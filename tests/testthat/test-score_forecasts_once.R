# generate_eval_data() scores each forecast once per target and summarizes
# those scores for each eval set and disaggregation. These tests check that it
# writes the same scores as scoring every eval set and disaggregation
# separately, which is what it did before.

# The previous algorithm: score each eval set, for each disaggregation.
generate_eval_data_per_eval_set <- function(hub_path, config_path, out_path) {
  config <- read_predevals_config(hub_path, config_path)
  hub_con <- hubData::connect_hub(hub_path)
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()
  oracle_output$as_of <- NULL
  for (target in config$targets) {
    target_id <- target$target_id
    transform <- resolve_target_transform(target, config$transform_defaults)
    task_groups_w_target <- get_task_groups_w_target(
      hub_path,
      target_id,
      config$rounds_idx
    )
    metric_name_to_output_type <- get_metric_name_to_output_type(
      task_groups_w_target,
      target$metrics
    )
    target_oracle <- filter_to_target(oracle_output, task_groups_w_target)
    for (eval_set in config$eval_sets) {
      model_out_tbl <- load_model_out_in_eval_set(
        hub_path,
        target_id,
        eval_set,
        config$rounds_idx,
        hub_con = hub_con
      )
      if (nrow(model_out_tbl) == 0) {
        next
      }
      for (by in c(list(NULL), as.list(target$disaggregate_by))) {
        get_and_save_scores(
          model_out_tbl = model_out_tbl,
          oracle_output = target_oracle,
          metric_name_to_output_type = metric_name_to_output_type,
          relative_metrics = target$relative_metrics,
          baseline = target$baseline,
          target_id = target_id,
          eval_set_name = eval_set$eval_set_name,
          by = by,
          out_path = out_path,
          transform = transform,
          task_groups_w_target = task_groups_w_target
        )
      }
    }
  }
}

# Run both algorithms; return their outcomes (output files, or error message).
run_both <- function(hub_path, config_path) {
  run <- function(fun) {
    out_path <- withr::local_tempdir(.local_envir = parent.frame(2))
    result <- tryCatch(
      suppressMessages(suppressWarnings(fun(hub_path, config_path, out_path))),
      error = function(e) e
    )
    if (inherits(result, "error")) {
      return(list(error = conditionMessage(result)))
    }
    files <- sort(list.files(out_path, pattern = "\\.csv$", recursive = TRUE))
    list(
      files = purrr::set_names(
        purrr::map(
          files,
          ~ utils::read.csv(file.path(out_path, .x), check.names = FALSE)
        ),
        files
      )
    )
  }
  # Count calls that score and summarize an eval set directly, i.e. that fall
  # back from scoring each forecast once.
  rescored <- 0
  once <- testthat::with_mocked_bindings(
    run(generate_eval_data),
    score_model_out = function(...) {
      if (isTRUE(list(...)$summarize %||% TRUE)) {
        rescored <<- rescored + 1
      }
      hubEvals::score_model_out(...)
    }
  )
  list(
    once = once,
    per_eval_set = run(generate_eval_data_per_eval_set),
    rescored = rescored
  )
}

expect_same_scores <- function(outcomes, label) {
  # Means are summed in a different order, so allow for floating point error.
  testthat::expect_equal(
    outcomes$once,
    outcomes$per_eval_set,
    tolerance = 1e-12,
    label = label
  )
  if (is.null(outcomes$once$error)) {
    testthat::expect_equal(
      outcomes$rescored,
      0,
      label = paste(label, "eval sets scored directly")
    )
  }
}

# A copy of the ecfh hub with an extra model, "Late-model", whose forecasts are
# for the 2023-05-20 round, and with the oracle values for those weeks removed,
# so none of its forecasts can be scored.
local_hub_with_unobserved_model <- function(env = parent.frame()) {
  hub_path <- withr::local_tempdir(.local_envir = env)
  src <- testthat::test_path("testdata", "ecfh")
  file.copy(
    list.files(src, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    hub_path,
    recursive = TRUE
  )

  late <- utils::read.csv(
    file.path(hub_path, "model-output", "PSI-DICE", "2023-01-14-PSI-DICE.csv"),
    colClasses = "character"
  )
  shift <- function(d) format(as.Date(d) + 18 * 7)
  late$reference_date <- shift(late$reference_date)
  late$target_end_date <- shift(late$target_end_date)
  dir.create(file.path(hub_path, "model-output", "Late-model"))
  utils::write.csv(
    late,
    file.path(
      hub_path,
      "model-output",
      "Late-model",
      "2023-05-20-Late-model.csv"
    ),
    row.names = FALSE
  )

  # Drop oracle rows from 2023-05-20 on, keeping the file otherwise as it is.
  oracle_path <- file.path(hub_path, "target-data", "oracle-output.csv")
  lines <- readLines(oracle_path)
  target_end_date <- vapply(strsplit(lines[-1], ",", fixed = TRUE), `[`, "", 2)
  writeLines(
    c(lines[1], lines[-1][target_end_date < "2023-05-20"]),
    oracle_path
  )
  hub_path
}

write_config <- function(config, env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".yaml", .local_envir = env)
  yaml::write_yaml(config, path)
  path
}


test_that("scores match scoring each eval set separately, across test configs", {
  hub_path <- test_path("testdata", "ecfh")
  configs <- c(
    # point and quantile outputs, relative metrics, overlapping and filtered eval sets
    "config_valid_mean_median_quantile_rel.yaml",
    # an eval set with no data
    "config_valid_set_filters_no_data.yaml",
    # appended log transform, and a pmf target without one
    "config_valid_transform_defaults.yaml",
    # log transform in place of the natural scale, with relative metrics
    "config_valid_transform_no_append_rel.yaml"
  )
  for (config in configs) {
    outcomes <- run_both(
      hub_path,
      test_path("testdata", "test_configs", config)
    )
    expect_same_scores(outcomes, config)
    # make sure the comparison wasn't vacuous
    expect_true(length(outcomes$once$files) > 0, label = config)
  }
})


test_that("scores match for per-target transforms, ordinal pmf and nowcast hubs", {
  two_target_hub <- withr::local_tempdir()
  setup_two_target_hub(two_target_hub)
  expect_same_scores(
    run_both(
      two_target_hub,
      test_path(
        "testdata",
        "test_configs",
        "config_valid_transform_per_target.yaml"
      )
    ),
    "per-target transforms"
  )

  ordinal_hub <- withr::local_tempdir()
  setup_ordinal_pmf_hub(ordinal_hub)
  expect_same_scores(
    run_both(ordinal_hub, write_ordinal_pmf_config(ordinal_hub)),
    "ordinal pmf"
  )

  expect_same_scores(
    run_both(
      test_path("testdata", "nowcast"),
      test_path("testdata", "test_configs", "config_valid_nowcast.yaml")
    ),
    "nowcast"
  )
})


test_that("each forecast is scored once, without summarizing", {
  hub_path <- test_path("testdata", "ecfh")
  calls <- list()
  testthat::local_mocked_bindings(
    score_model_out = function(model_out_tbl, ...) {
      args <- list(...)
      calls[[length(calls) + 1]] <<- list(
        models = unique(model_out_tbl$model_id),
        output_type = unique(model_out_tbl$output_type),
        n = nrow(model_out_tbl),
        summarize = isTRUE(args$summarize %||% TRUE)
      )
      hubEvals::score_model_out(model_out_tbl, ...)
    }
  )
  out_path <- withr::local_tempdir()
  suppressMessages(generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile_rel.yaml"
    ),
    out_path = out_path
  ))

  expect_false(any(purrr::map_lgl(calls, "summarize")))
  # one call per model and output type
  call_ids <- purrr::map_chr(calls, ~ paste(.x$models, .x$output_type))
  expect_true(all(purrr::map_int(calls, ~ length(.x$models)) == 1))
  expect_equal(anyDuplicated(call_ids), 0)
  # every row in any eval set is scored, and only once
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(
      target == "wk inc flu hosp",
      output_type %in% c("mean", "median", "quantile"),
      reference_date >= "2022-10-22"
    )
  expect_equal(sum(purrr::map_int(calls, "n")), nrow(model_out_tbl))
})


test_that("a model with nothing to score is left out, as when scoring each eval set", {
  hub_path <- local_hub_with_unobserved_model()
  config <- yaml::read_yaml(test_path(
    "testdata",
    "test_configs",
    "config_valid_mean_median_quantile_rel.yaml"
  ))
  config$eval_sets <- config$eval_sets[1]
  outcomes <- run_both(hub_path, write_config(config))
  expect_same_scores(outcomes, "unobserved model")
  expect_false(
    "Late-model" %in%
      outcomes$once$files[["wk inc flu hosp/Full season/scores.csv"]]$model_id
  )
})


test_that("an eval set with nothing to score behaves as when scoring each eval set", {
  hub_path <- local_hub_with_unobserved_model()
  config <- yaml::read_yaml(test_path(
    "testdata",
    "test_configs",
    "config_valid_mean_median_quantile_rel.yaml"
  ))
  config$eval_sets <- list(list(
    eval_set_name = "Unobserved",
    round_filters = list(min = "2023-05-20")
  ))
  outcomes <- run_both(hub_path, write_config(config))
  expect_match(outcomes$per_eval_set$error, "no forecasts")
  expect_identical(outcomes$once, outcomes$per_eval_set)
  # this is the case that falls back to scoring the eval set directly
  expect_gt(outcomes$rescored, 0)

  # the same, when another eval set's forecasts were scored
  config$eval_sets <- c(
    list(list(
      eval_set_name = "Full season",
      round_filters = list(min = "2022-10-22")
    )),
    config$eval_sets
  )
  outcomes <- run_both(hub_path, write_config(config))
  expect_match(outcomes$per_eval_set$error, "no forecasts")
  expect_identical(outcomes$once, outcomes$per_eval_set)
  expect_gt(outcomes$rescored, 0)
})


test_that("a target with no forecasts in any eval set writes nothing, as before", {
  config <- yaml::read_yaml(test_path(
    "testdata",
    "test_configs",
    "config_valid_set_filters_no_data.yaml"
  ))
  # keep only the eval set for locations with no data in the test hub
  config$eval_sets <- config$eval_sets[3]
  outcomes <- run_both(test_path("testdata", "ecfh"), write_config(config))
  expect_same_scores(outcomes, "no forecasts")
  expect_length(outcomes$once$files, 0)
})


test_that("scores match when a model doesn't submit every output type", {
  hub_path <- withr::local_tempdir()
  src <- test_path("testdata", "ecfh")
  file.copy(
    list.files(src, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    hub_path,
    recursive = TRUE
  )
  # MOBS-GLEAM submits no medians
  model_dir <- file.path(hub_path, "model-output", "MOBS-GLEAM")
  for (path in list.files(model_dir, full.names = TRUE)) {
    lines <- readLines(path)
    writeLines(lines[!grepl(',"median",', lines, fixed = TRUE)], path)
  }
  config <- yaml::read_yaml(test_path(
    "testdata",
    "test_configs",
    "config_valid_mean_median_quantile_rel.yaml"
  ))
  config$eval_sets <- config$eval_sets[1]
  outcomes <- run_both(hub_path, write_config(config))
  expect_same_scores(outcomes, "model without medians")
  scores <- outcomes$once$files[["wk inc flu hosp/Full season/scores.csv"]]
  expect_true(is.na(scores$ae_point[scores$model_id == "MOBS-GLEAM"]))
})


test_that("scoring errors other than missing observations still stop the run", {
  hub_path <- withr::local_tempdir()
  src <- test_path("testdata", "ecfh")
  file.copy(
    list.files(src, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    hub_path,
    recursive = TRUE
  )
  path <- file.path(
    hub_path,
    "model-output",
    "PSI-DICE",
    "2023-01-14-PSI-DICE.csv"
  )
  rows <- utils::read.csv(path, colClasses = "character")
  # the same quantiles again with different values: duplicate forecasts
  dup <- rows[rows$output_type == "quantile", ][1:3, ]
  dup$value <- as.character(as.numeric(dup$value) + 1)
  utils::write.csv(rbind(rows, dup), path, row.names = FALSE)

  outcomes <- run_both(
    hub_path,
    test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile.yaml"
    )
  )
  # Scoring each eval set wraps the same error in purrr's "In index" context.
  expect_match(
    outcomes$once$error,
    "more than one forecast for the same target",
    fixed = TRUE
  )
  expect_match(
    outcomes$per_eval_set$error,
    "more than one forecast for the same target",
    fixed = TRUE
  )
})


test_that("scores.csv is identical across runs", {
  hub_path <- test_path("testdata", "ecfh")
  config_path <- test_path(
    "testdata",
    "test_configs",
    "config_valid_transform_defaults.yaml"
  )
  runs <- purrr::map(1:2, function(i) {
    out_path <- withr::local_tempdir(.local_envir = parent.frame(2))
    suppressMessages(suppressWarnings(generate_eval_data(
      hub_path,
      config_path,
      out_path
    )))
    files <- sort(list.files(out_path, pattern = "\\.csv$", recursive = TRUE))
    purrr::map(files, ~ readLines(file.path(out_path, .x)))
  })
  expect_identical(runs[[1]], runs[[2]])
})
