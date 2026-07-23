test_that("generate_eval_data works, integration test, no relative metrics", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect()
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile.yaml"
    ),
    out_path = out_path
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
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  suppress_wilcox_ties_warnings(generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile_rel.yaml"
    ),
    out_path = out_path
  ))

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


test_that("supplying oracle_output produces output identical to internal discovery", {
  # Back-compat lock-in: callers (e.g. docker images pinned to older script
  # versions) that pre-load oracle output and pass it in must produce the
  # exact same scores files as the default internal-discovery path. Also
  # useful for tests that want to inject a tailored frame.
  hub_path <- test_path("testdata", "ecfh")
  config_path <- test_path(
    "testdata",
    "test_configs",
    "config_valid_mean_median_quantile_rel.yaml"
  )
  out_supplied <- withr::local_tempdir()
  out_discovered <- withr::local_tempdir()
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  suppress_wilcox_ties_warnings(generate_eval_data(
    hub_path = hub_path,
    config_path = config_path,
    out_path = out_supplied,
    oracle_output = oracle_output
  ))
  suppress_wilcox_ties_warnings(generate_eval_data(
    hub_path = hub_path,
    config_path = config_path,
    out_path = out_discovered
  ))

  files_supplied <- sort(list.files(out_supplied, recursive = TRUE))
  files_discovered <- sort(list.files(out_discovered, recursive = TRUE))
  expect_identical(files_supplied, files_discovered)
  # scoringutils outputs are not bit-stable across platforms (acknowledged
  # upstream in epiforecasts/scoringutils#1182), so the back-compat lock-in
  # tolerates last-digit float noise rather than asserting bit-exact equality.
  for (f in files_supplied) {
    expect_equal(
      read.csv(file.path(out_supplied, f)),
      read.csv(file.path(out_discovered, f)),
      info = f
    )
  }
})


test_that("generate_eval_data tolerates an as_of column in oracle output", {
  # Versioned target-data carries an `as_of` provenance column (#70) that
  # hubEvals scoring would reject. generate_eval_data should drop it and score
  # without error.
  hub_path <- test_path("testdata", "ecfh")
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()
  oracle_output$as_of <- as.Date("2026-06-10")

  expect_no_error(generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_mean_median_quantile.yaml"
    ),
    out_path = withr::local_tempdir(),
    oracle_output = oracle_output
  ))
})


test_that("generate_eval_data resolves and applies per-target transforms independently across targets", {
  hub_path <- withr::local_tempdir()
  out_path <- withr::local_tempdir()
  config_path <- file.path(hub_path, "predevals-config.yaml")
  setup_two_target_hub(hub_path)

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
    out_path = out_path
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
      out_path = out_path
    )
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

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_transform_per_target.yaml"
    ),
    out_path = out_path
  )

  natural_metrics <- c(
    "wis",
    "ae_median",
    "interval_coverage_50",
    "interval_coverage_95"
  )
  # Interval coverage is invariant under monotonic transforms (#63), so the
  # pipeline drops its transformed-scale columns from scores.csv.
  transformed_metrics <- c("wis__log", "ae_median__log")

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
    # Interval coverage is invariant under monotonic transforms (#63), so its
    # transformed-scale columns must not appear at any aggregation level.
    expect_false(any(
      c("interval_coverage_50__log", "interval_coverage_95__log") %in%
        names(scores)
    ))
    expect_true("n" %in% names(scores))
    id_cols <- c("model_id", if (!is.null(by)) by)
    expect_equal(
      nrow(dplyr::distinct(scores[, id_cols, drop = FALSE])),
      nrow(scores)
    )
    expect_false(any(is.na(scores$wis)))
    expect_false(any(is.na(scores$wis__log)))
  }

  # Columns are bunched per metric: each metric's natural column is
  # immediately followed by its transformed-scale column.
  overall_scores <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  expect_identical(
    names(overall_scores),
    c(
      "model_id",
      "wis",
      "wis__log",
      "ae_median",
      "ae_median__log",
      "interval_coverage_50",
      "interval_coverage_95",
      "n"
    )
  )

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

  expect_no_error(
    generate_eval_data(
      hub_path = hub_path,
      config_path = config_path,
      out_path = out_path
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
      out_path = out_path
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

  generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_transform_no_append.yaml"
    ),
    out_path = out_path
  )

  scores <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  # Proper-scoring-rule metrics appear only on the transformed scale.
  expect_true(all(c("wis__log", "ae_median__log") %in% names(scores)))
  expect_false(any(c("wis", "ae_median") %in% names(scores)))
  # Interval coverage is invariant under monotonic transforms (#63), so its
  # column keeps the natural-scale name even when append=FALSE.
  expect_true(all(
    c("interval_coverage_50", "interval_coverage_95") %in% names(scores)
  ))
  expect_false(any(
    c("interval_coverage_50__log", "interval_coverage_95__log") %in%
      names(scores)
  ))
})


test_that("generate_eval_data scores relative skill on the transformed scale when append=FALSE", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")

  suppress_wilcox_ties_warnings(generate_eval_data(
    hub_path = hub_path,
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_transform_no_append_rel.yaml"
    ),
    out_path = out_path
  ))

  scores <- read.csv(
    file.path(out_path, "wk inc flu hosp", "Full season", "scores.csv")
  )
  # append=FALSE emits only transformed-scale columns, including the
  # relative-skill columns computed on the transformed scale. Columns are
  # bunched per metric: scaled relative skill, then the base metric. Interval
  # coverage is invariant under monotonic transforms (#63), so it keeps its
  # natural-scale name.
  expect_identical(
    names(scores),
    c(
      "model_id",
      "wis_scaled_relative_skill__log",
      "wis__log",
      "ae_median_scaled_relative_skill__log",
      "ae_median__log",
      "interval_coverage_50",
      "interval_coverage_95",
      "n"
    )
  )
})


test_that("generate_eval_data generates an informative message and partial results if an evaluation set has no data", {
  out_path <- withr::local_tempdir()
  hub_path <- test_path("testdata", "ecfh")
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect()
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  expect_message(
    generate_eval_data(
      hub_path = hub_path,
      config_path = test_path(
        "testdata",
        "test_configs",
        "config_valid_set_filters_no_data.yaml"
      ),
      out_path = out_path
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


test_that("a model scored only on a non-anchor output type survives the merge (#75)", {
  # metrics = c("se_point", "wis") map to output types c("mean", "quantile"),
  # so the per-output-type merge anchors on `mean` (the first type). A model
  # submitting only `quantile` is absent from that anchor frame and, under the
  # old left_join, would be silently dropped along with its valid wis. The
  # full_join keeps it with NA in the columns it did not submit.
  hub_path <- test_path("testdata", "ecfh")
  target_id <- "wk inc flu hosp"
  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id, 0)
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    c("se_point", "wis")
  )
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(target == target_id)
  # PSI-DICE now submits no `mean` (anchor) output, only quantile etc.
  model_out_tbl <- model_out_tbl |>
    dplyr::filter(!(model_id == "PSI-DICE" & output_type == "mean"))

  out_path <- withr::local_tempdir()
  get_and_save_scores(
    model_out_tbl = model_out_tbl,
    oracle_output = oracle_output,
    metric_name_to_output_type = metric_name_to_output_type,
    relative_metrics = NULL,
    baseline = NULL,
    target_id = target_id,
    eval_set_name = "set",
    by = NULL,
    out_path = out_path,
    transform = NULL,
    task_groups_w_target = task_groups_w_target
  )
  scores <- read.csv(
    file.path(out_path, target_id, "set", "scores.csv")
  )

  expect_true("PSI-DICE" %in% scores$model_id)
  psi <- scores[scores$model_id == "PSI-DICE", ]
  expect_true(is.na(psi$se_point))
  expect_true(is.finite(psi$wis))
})


test_that("a (model, by) cell present only on a non-anchor output type survives the merge (#75)", {
  # Disaggregated tables merge on the finer key c("model_id", by), so the drop
  # happens per cell: a model can look fully present at the overall level yet
  # lose individual cells wherever its anchor-type coverage has a gap a later
  # type fills. Here PSI-DICE submits `mean` everywhere except location "US",
  # where it submits only quantile, so the US cell exists solely on the
  # non-anchor type.
  hub_path <- test_path("testdata", "ecfh")
  target_id <- "wk inc flu hosp"
  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id, 0)
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    c("se_point", "wis")
  )
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(target == target_id)
  model_out_tbl <- model_out_tbl |>
    dplyr::filter(
      !(model_id == "PSI-DICE" & output_type == "mean" & location == "US")
    )

  out_path <- withr::local_tempdir()
  get_and_save_scores(
    model_out_tbl = model_out_tbl,
    oracle_output = oracle_output,
    metric_name_to_output_type = metric_name_to_output_type,
    relative_metrics = NULL,
    baseline = NULL,
    target_id = target_id,
    eval_set_name = "set",
    by = "location",
    out_path = out_path,
    transform = NULL,
    task_groups_w_target = task_groups_w_target
  )
  scores <- read.csv(
    file.path(out_path, target_id, "set", "location", "scores.csv")
  )

  us_psi <- scores[scores$model_id == "PSI-DICE" & scores$location == "US", ]
  expect_equal(nrow(us_psi), 1)
  expect_true(is.na(us_psi$se_point))
  expect_true(is.finite(us_psi$wis))
})


test_that("scores.csv row order is deterministic regardless of input row order (#25)", {
  # arrow's parallel collect in load_model_out_in_eval_set() returns rows in a
  # nondeterministic order and hubEvals::score_model_out() carries that order
  # into its output, so two runs on identical data used to emit the same rows
  # shuffled. get_and_save_scores() now arranges on the (model_id, by) key
  # before writing. Feeding deliberately reverse-ordered input must still yield
  # output in that canonical order, for both the overall (key model_id only)
  # and disaggregated (key model_id + by) paths.
  hub_path <- test_path("testdata", "ecfh")
  target_id <- "wk inc flu hosp"
  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id, 0)
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    "wis"
  )
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()
  reversed_input <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(target == target_id)
  # There is no error or warning if the arrange is dropped; the test can only
  # catch that by comparing row order. But scoring might return rows already in
  # canonical order by chance, in which case the output would pass even without
  # the arrange. Reversing the input first guarantees that a dropped arrange
  # yields reverse-ordered (non-canonical) output, so the assertion fails.
  reversed_input <- reversed_input[rev(seq_len(nrow(reversed_input))), ]

  for (by in list(NULL, "location")) {
    out_path <- withr::local_tempdir()
    get_and_save_scores(
      model_out_tbl = reversed_input,
      oracle_output = oracle_output,
      metric_name_to_output_type = metric_name_to_output_type,
      relative_metrics = NULL,
      baseline = NULL,
      target_id = target_id,
      eval_set_name = "set",
      by = by,
      out_path = out_path,
      transform = NULL,
      task_groups_w_target = task_groups_w_target
    )
    score_dir <- file.path(out_path, target_id, "set")
    if (!is.null(by)) {
      score_dir <- file.path(score_dir, by)
    }
    scores <- read.csv(file.path(score_dir, "scores.csv"))
    expect_equal(
      scores,
      dplyr::arrange(scores, dplyr::across(dplyr::all_of(c("model_id", by)))),
      info = paste("by =", deparse(by))
    )
  }
})


test_that("n counts only forecasts with a matching oracle observation (#19)", {
  # The scored count must exclude submitted forecasts that had no oracle
  # observation to be scored against. Dropping the observations for one location
  # leaves those location's quantile forecasts unscored, so `n` must fall by
  # exactly the number of forecast units in that location, not stay at the count
  # of all submitted units (the pre-#19 behaviour).
  hub_path <- test_path("testdata", "ecfh")
  target_id <- "wk inc flu hosp"
  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id, 0)
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    "wis"
  )
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(target == target_id)
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  dropped_loc <- "US"
  partial_oracle <- oracle_output |> dplyr::filter(location != dropped_loc)

  # Independent expectation: one scored unit per distinct quantile forecast unit
  # (task-id combination) that has an observation. The oracle is complete, so
  # with the full oracle every submitted unit is scored; with the partial oracle
  # the dropped location's units are not.
  q_units <- model_out_tbl |>
    dplyr::filter(output_type == "quantile") |>
    dplyr::distinct(
      model_id,
      location,
      reference_date,
      horizon,
      target_end_date
    )
  exp_full <- q_units |> dplyr::count(model_id, name = "n")
  exp_partial <- q_units |>
    dplyr::filter(location != dropped_loc) |>
    dplyr::count(model_id, name = "n")

  score_n <- function(oracle) {
    out_path <- withr::local_tempdir()
    get_and_save_scores(
      model_out_tbl = model_out_tbl,
      oracle_output = oracle,
      metric_name_to_output_type = metric_name_to_output_type,
      relative_metrics = NULL,
      baseline = NULL,
      target_id = target_id,
      eval_set_name = "set",
      by = NULL,
      out_path = out_path,
      transform = NULL,
      task_groups_w_target = task_groups_w_target
    )
    read.csv(file.path(out_path, target_id, "set", "scores.csv"))[c(
      "model_id",
      "n"
    )]
  }

  n_full <- score_n(oracle_output)
  n_partial <- score_n(partial_oracle)

  expect_equal(n_full, as.data.frame(exp_full), ignore_attr = TRUE)
  expect_equal(n_partial, as.data.frame(exp_partial), ignore_attr = TRUE)
  # And the fix actually changed something: fewer scored units once observations
  # are missing.
  expect_true(all(n_partial$n < n_full$n))
})


test_that("diverging per-output-type counts are kept as n_<output_type> columns (#19)", {
  # When a model submits the same output types on different unit sets, the
  # scored counts legitimately differ across types. Mock scoring so `mean` and
  # `quantile` report different counts for modelA; the merged table must keep
  # both `n_mean` and `n_quantile`, each immediately after the metric block it
  # refers to, rather than collapsing to a single (wrong) `n`.
  hub_path <- test_path("testdata", "ecfh")
  target_id <- "wk inc flu hosp"
  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id, 0)
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    c("se_point", "wis")
  )
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(target == target_id)
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  testthat::local_mocked_bindings(
    score_model_out = function(model_out_tbl, metrics, ...) {
      if ("wis" %in% metrics) {
        dplyr::tibble(
          model_id = c("modelA", "modelB"),
          wis = c(0.1, 0.2),
          count = c(12L, 12L)
        )
      } else {
        dplyr::tibble(
          model_id = c("modelA", "modelB"),
          se_point = c(2, 3),
          count = c(10L, 12L)
        )
      }
    }
  )

  out_path <- withr::local_tempdir()
  get_and_save_scores(
    model_out_tbl = model_out_tbl,
    oracle_output = oracle_output,
    metric_name_to_output_type = metric_name_to_output_type,
    relative_metrics = NULL,
    baseline = NULL,
    target_id = target_id,
    eval_set_name = "set",
    by = NULL,
    out_path = out_path,
    transform = NULL,
    task_groups_w_target = task_groups_w_target
  )
  scores <- read.csv(file.path(out_path, target_id, "set", "scores.csv"))

  expect_false("n" %in% names(scores))
  expect_identical(
    names(scores),
    c("model_id", "se_point", "n_mean", "wis", "n_quantile")
  )
  modela <- scores[scores$model_id == "modelA", ]
  expect_equal(modela$n_mean, 10)
  expect_equal(modela$n_quantile, 12)
})


test_that("agreeing per-output-type counts collapse to a single n (#19)", {
  # The common case: counts never disagree across output types. modelA submits
  # both types on the same units (equal counts); modelB submits only quantile
  # (mean count NA). Neither row carries two differing counts, so the table
  # collapses to a single `n` column after the metrics.
  hub_path <- test_path("testdata", "ecfh")
  target_id <- "wk inc flu hosp"
  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id, 0)
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    c("se_point", "wis")
  )
  model_out_tbl <- hubData::connect_hub(hub_path) |>
    dplyr::collect() |>
    dplyr::filter(target == target_id)
  oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
    dplyr::collect()

  testthat::local_mocked_bindings(
    score_model_out = function(model_out_tbl, metrics, ...) {
      if ("wis" %in% metrics) {
        dplyr::tibble(
          model_id = c("modelA", "modelB"),
          wis = c(0.1, 0.2),
          count = c(12L, 12L)
        )
      } else {
        # modelB submits no mean output
        dplyr::tibble(model_id = "modelA", se_point = 2, count = 12L)
      }
    }
  )

  out_path <- withr::local_tempdir()
  get_and_save_scores(
    model_out_tbl = model_out_tbl,
    oracle_output = oracle_output,
    metric_name_to_output_type = metric_name_to_output_type,
    relative_metrics = NULL,
    baseline = NULL,
    target_id = target_id,
    eval_set_name = "set",
    by = NULL,
    out_path = out_path,
    transform = NULL,
    task_groups_w_target = task_groups_w_target
  )
  scores <- read.csv(file.path(out_path, target_id, "set", "scores.csv"))

  expect_false(any(c("n_mean", "n_quantile") %in% names(scores)))
  expect_identical(names(scores), c("model_id", "se_point", "wis", "n"))
  expect_equal(scores$n, c(12, 12))
})
