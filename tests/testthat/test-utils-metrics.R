test_that("get_metric_name_to_output_type works, no ordinal targets", {
  task_groups <- list(
    list(
      output_type = list(
        "mean" = list(),
        "quantile" = list()
      ),
      target_metadata = list(
        list(target_type = "continuous")
      )
    ),
    list(
      output_type = list(
        "median" = list()
      ),
      target_metadata = list(
        list(target_type = "continuous")
      )
    ),
    list(
      output_type = list(
        "pmf" = list()
      ),
      target_metadata = list(
        list(target_type = "nominal")
      )
    )
  )
  metrics <- c(
    "se_point",
    "ae_point",
    "interval_coverage_50",
    "wis",
    "ae_median",
    "NOT A REAL METRIC",
    "log_score",
    "rps"
  )

  # note: the "rps" metric is only supported for ordinal pmf targets
  expect_equal(
    get_metric_name_to_output_type(task_groups, metrics),
    data.frame(
      metric = metrics,
      output_type = c(
        "mean",
        "median",
        "quantile",
        "quantile",
        "quantile",
        NA_character_,
        "pmf",
        NA_character_
      )
    )
  )
})


test_that("get_metric_name_to_output_type works, ordinal target", {
  task_groups <- list(
    list(
      output_type = list(
        "pmf" = list()
      ),
      target_metadata = list(
        list(target_type = "ordinal")
      )
    )
  )
  metrics <- c(
    "se_point",
    "ae_point",
    "interval_coverage_50",
    "wis",
    "ae_median",
    "NOT A REAL METRIC",
    "log_score",
    "rps"
  )

  expect_equal(
    get_metric_name_to_output_type(task_groups, metrics),
    data.frame(
      metric = metrics,
      output_type = c(rep(NA_character_, 6), "pmf", "pmf")
    )
  )
})


test_that("expand_relative_skill_metrics splices relative-skill entries", {
  expect_identical(
    expand_relative_skill_metrics(
      metrics = c("wis", "ae_median", "interval_coverage_50"),
      relative_metrics = c("wis", "ae_median")
    ),
    c(
      "wis_scaled_relative_skill",
      "wis",
      "ae_median_scaled_relative_skill",
      "ae_median",
      "interval_coverage_50"
    )
  )
})


test_that("expand_relative_skill_metrics is a no-op with no relative metrics", {
  expect_identical(
    expand_relative_skill_metrics(
      metrics = c("wis", "ae_median"),
      relative_metrics = NULL
    ),
    c("wis", "ae_median")
  )
})


test_that("expand_transformed_metrics interleaves when append=TRUE", {
  expect_identical(
    expand_transformed_metrics(
      expanded_metrics = c("wis_scaled_relative_skill", "wis", "ae_median"),
      transformable_metrics = c("wis", "ae_median"),
      label = "log",
      append = TRUE
    ),
    c(
      "wis_scaled_relative_skill",
      "wis_scaled_relative_skill__log",
      "wis",
      "wis__log",
      "ae_median",
      "ae_median__log"
    )
  )
})


test_that("expand_transformed_metrics replaces when append=FALSE", {
  expect_identical(
    expand_transformed_metrics(
      expanded_metrics = c("wis_scaled_relative_skill", "wis", "ae_median"),
      transformable_metrics = c("wis", "ae_median"),
      label = "log",
      append = FALSE
    ),
    c(
      "wis_scaled_relative_skill__log",
      "wis__log",
      "ae_median__log"
    )
  )
})


test_that("expand_transformed_metrics skips non-transformable metrics", {
  expect_identical(
    expand_transformed_metrics(
      expanded_metrics = c("wis", "log_score"),
      transformable_metrics = "wis",
      label = "log",
      append = TRUE
    ),
    c("wis", "wis__log", "log_score")
  )
})
