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
