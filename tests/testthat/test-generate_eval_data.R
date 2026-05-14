test_that("generate_eval_data works, integration test, no relative metrics", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect()
  oracle_output <- read.csv(
    test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
  )
  oracle_output[["target_end_date"]] <- as.Date(oracle_output[[
    "target_end_date"
  ]])

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile.yaml"
    ),
    out_path = out_path,
    oracle_output = oracle_output
  )

  check_exp_scores_for_set(
    out_path,
    "Full season",
    model_out_tbl,
    oracle_output
  )
  check_exp_scores_for_set(
    out_path,
    "Last 5 weeks",
    model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
    oracle_output
  )
  check_exp_scores_for_set(
    out_path,
    "Alabama, positive horizons",
    model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
    oracle_output
  )
})

test_that("generate_eval_data works, integration test, with relative metrics", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect()
  oracle_output <- read.csv(
    test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
  )
  oracle_output[["target_end_date"]] <- as.Date(oracle_output[[
    "target_end_date"
  ]])

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile_rel.yaml"
    ),
    out_path = out_path,
    oracle_output = oracle_output
  )

  check_exp_scores_for_set(
    out_path,
    "Full season",
    model_out_tbl,
    oracle_output,
    include_rel = TRUE
  )
  check_exp_scores_for_set(
    out_path,
    "Last 5 weeks",
    model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
    oracle_output,
    include_rel = TRUE
  )
  check_exp_scores_for_set(
    out_path,
    "Alabama, positive horizons",
    model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
    oracle_output,
    include_rel = TRUE
  )
})

test_that("generate_eval_data resolves and applies per-target transforms independently across targets", {
  hub_path <- withr::local_tempdir()
  out_path <- withr::local_tempdir()
  config_path <- file.path(hub_path, "predevals-config.yaml")
  setup_two_target_hub(hub_path)
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  yaml::write_yaml(
    list(
      schema_version = paste0(
        "https://raw.githubusercontent.com/hubverse-org/",
        "hubPredEvalsData/main/inst/schema/v1.1.0/config_schema.json"
      ),
      rounds_idx = 0L,
      targets = list(
        list(
          target_id = "wk inc flu hosp",
          metrics = list("wis"),
          transform = list(
            fun = "log_shift",
            args = list(offset = 1),
            append = TRUE
          )
        ),
        list(
          target_id = "wk inc flu death",
          metrics = list("wis"),
          transform = list(
            fun = "sqrt",
            append = TRUE
          )
        )
      ),
      eval_sets = list(list(
        eval_set_name = "Full season",
        round_filters = list(min = "2022-10-22")
      ))
    ),
    config_path
  )

  generate_eval_data(
    hub_path = hub_path,
    config_path = config_path,
    out_path = out_path,
    oracle_output = oracle_output
  )

  scores_log <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  expect_true(all(c("wis", "wis__log_shift") %in% names(scores_log)))
  expect_false("wis__sqrt" %in% names(scores_log))

  scores_sqrt <- read.csv(
    file.path(out_path, "wk inc flu death", "Full season", "scores.csv")
  )
  expect_true(all(c("wis", "wis__sqrt") %in% names(scores_sqrt)))
  expect_false("wis__log_shift" %in% names(scores_sqrt))

  # The two targets should produce different transformed-scale WIS, confirming
  # the transforms are not silently aliased to one another.
  expect_false(
    isTRUE(all.equal(scores_log$wis__log_shift, scores_sqrt$wis__sqrt))
  )
})


test_that("generate_eval_data forwards transform args to score_model_out (log_shift offset handles zeros)", {
  # config_valid_transform_per_target.yaml configures
  # transform: { fun: log_shift, args: { offset: 1 } } for "wk inc flu hosp".
  # The ecfh oracle contains true-zero observations for low-incidence
  # locations. Without the offset, log_shift(0) is -Inf (and scoringutils
  # emits a "Detected zeros" warning); a finite, warning-free WIS on the
  # transformed scale is only possible if `args.offset` actually reached
  # scoringutils::transform_forecasts.
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  # Sanity check: there ARE zero observations for the transformed target,
  # otherwise this test would not exercise the offset.
  q_obs <- oracle_output$oracle_value[
    oracle_output$target == "wk inc flu hosp" &
      oracle_output$output_type == "quantile"
  ]
  expect_true(any(q_obs == 0))

  expect_no_warning(
    generate_eval_data(
      hub_path = hub_path,
      config_path = test_path(
        "testdata",
        "test_configs",
        "config_valid_transform_per_target.yaml"
      ),
      out_path = out_path,
      oracle_output = oracle_output
    ),
    message = "Detected zeros"
  )

  scores <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  expect_true(all(is.finite(scores$wis__log)))
  expect_true(all(is.finite(scores$ae_median__log)))
})


test_that("generate_eval_data applies per-target transform with append=TRUE", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_transform_per_target.yaml"
    ),
    out_path = out_path,
    oracle_output = oracle_output
  )

  natural_metrics <- c(
    "wis",
    "ae_median",
    "interval_coverage_50",
    "interval_coverage_95"
  )
  transformed_metrics <- paste0(natural_metrics, "__log")

  # generate_eval_data emits an overall scores.csv plus one per "by" task_id
  # the config requests aggregation by. Iterate over all of them to confirm
  # the transform is applied uniformly at every aggregation level, not just
  # the overall summary.
  for (by in list(
    NULL,
    "location",
    "reference_date",
    "horizon",
    "target_end_date"
  )) {
    scores_dir <- file.path(out_path, "wk inc flu hosp", "Full season")
    scores_path <- if (is.null(by)) {
      file.path(scores_dir, "scores.csv")
    } else {
      file.path(scores_dir, by, "scores.csv")
    }
    expect_true(file.exists(scores_path))

    scores <- read.csv(scores_path)
    expect_true(all(c(natural_metrics, transformed_metrics) %in% names(scores)))
    expect_true("n" %in% names(scores))
    id_cols <- c("model_id", if (!is.null(by)) by)
    expect_equal(
      nrow(dplyr::distinct(scores[, id_cols, drop = FALSE])),
      nrow(scores)
    )
    expect_false(any(is.na(scores$wis)))
    expect_false(any(is.na(scores$wis__log)))
  }

  # pmf target inherits no transform (no transform_defaults set in this config),
  # so its scores file has no label-suffixed columns.
  pmf_scores <- read.csv(
    file.path(
      out_path,
      "wk flu hosp rate category",
      "Full season",
      "scores.csv"
    )
  )
  expect_true("log_score" %in% names(pmf_scores))
  expect_false(any(grepl("__log$", names(pmf_scores))))
})


test_that("generate_eval_data scores rps on ordinal pmf targets (#48)", {
  # Without output_type_id_order, scoringutils dispatches pmf data as
  # forecast_nominal and rejects rps with "Must be a subset of {'log_score'}".
  # generate_eval_data must read the ordinal level order from the hub's
  # tasks.json and forward it to score_model_out().
  #
  # Uses a synthetic hub rather than ecfh because the ecfh pmf rows drift from
  # summing to exactly 1 by ~2e-8, which scoringRules::rps_probs still rejects
  # under its `<= .Machine$double.eps` check (tracked at hubEvals#74). Powers
  # of 1/2 here sum to exactly 1.0 in IEEE 754, so rps actually computes.
  hub_path <- withr::local_tempdir()
  out_path <- withr::local_tempdir()
  setup_ordinal_pmf_hub(hub_path)
  config_path <- write_ordinal_pmf_config(hub_path)

  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  expect_no_error(
    generate_eval_data(
      hub_path = hub_path,
      config_path = config_path,
      out_path = out_path,
      oracle_output = oracle_output
    )
  )

  scores <- read.csv(
    file.path(out_path, "hosp rate category", "Full", "scores.csv")
  )
  expect_true(all(c("log_score", "rps") %in% names(scores)))
  expect_true(all(is.finite(scores$log_score)))
  expect_true(all(is.finite(scores$rps)))

  # good-model concentrates mass at the truth bin; bad-model concentrates at
  # the opposite end. If output_type_id_order were dropped, mis-ordered, or
  # reversed, this comparison would no longer reflect the underlying skill.
  good <- scores[scores$model_id == "good-model", ]
  bad <- scores[scores$model_id == "bad-model", ]
  expect_lt(good$rps, bad$rps)
  expect_lt(good$log_score, bad$log_score)
})


test_that("generate_eval_data applies transform_defaults to inheriting targets and skips opt-out targets", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  # The opted-out target ("wk flu hosp rate category") is pmf-only, so it
  # could not be transformed even if it tried. Without `transform: false`,
  # validate_transform_output_types would emit an "Inherited transform_defaults
  # cannot apply" warning here; `transform: false` is what silences it. Check
  # that explicitly, since the absence of __log_shift columns below would hold
  # either way for a non-transformable target.
  expect_no_warning(
    generate_eval_data(
      hub_path = hub_path,
      config_path = test_path(
        "testdata",
        "test_configs",
        "config_valid_transform_defaults.yaml"
      ),
      out_path = out_path,
      oracle_output = oracle_output
    )
  )

  # inheriting target gets transform (label inferred from function name -> "log_shift")
  inheriting <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  expect_true("wis" %in% names(inheriting))
  expect_true("wis__log_shift" %in% names(inheriting))

  # opted-out target (transform: false) gets no transform applied
  opted_out <- read.csv(
    file.path(
      out_path,
      "wk flu hosp rate category",
      "Full season",
      "scores.csv"
    )
  )
  expect_true("log_score" %in% names(opted_out))
  expect_false(any(grepl("__log_shift$", names(opted_out))))
})


test_that("generate_eval_data with transform append=FALSE emits only transformed-scale columns", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_transform_no_append.yaml"
    ),
    out_path = out_path,
    oracle_output = oracle_output
  )

  scores <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  expect_true(all(
    c(
      "wis__log",
      "ae_median__log",
      "interval_coverage_50__log",
      "interval_coverage_95__log"
    ) %in%
      names(scores)
  ))
  expect_false(any(
    c("wis", "ae_median", "interval_coverage_50", "interval_coverage_95") %in%
      names(scores)
  ))
})


test_that("generate_eval_data generates an informative message and partial results if an evaluation set has no data", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect()
  oracle_output <- read.csv(
    test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
  )
  oracle_output[["target_end_date"]] <- as.Date(oracle_output[[
    "target_end_date"
  ]])

  expect_message(
    generate_eval_data(
      hub_path = hub_path,
      config_path = test_path(
        "testdata",
        "test_configs",
        "config_valid_set_filters_no_data.yaml"
      ),
      out_path = out_path,
      oracle_output = oracle_output
    ),
    'No model output data found for target "wk inc flu hosp" in evaluation set "Valid locations with no data in test'
  )

  check_exp_scores_for_set(
    out_path,
    "Full season",
    model_out_tbl,
    oracle_output,
    include_rel = FALSE
  )
  check_exp_scores_for_set(
    out_path,
    "Last 5 weeks",
    model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
    oracle_output,
    include_rel = FALSE
  )
})
