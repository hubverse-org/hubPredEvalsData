#' Get a data frame with 1 row for each metric, matching the metric with the
#' output type to use for calculating the metric.  If the metric is invalid or
#' can't be calculated from the available output types for the target, the
#' output_type will be NA.
#'
#' This implementation is somewhat fragile.  It assumes that all metrics are
#' either an interval coverage (to be computed based on quantile forecasts) or
#' a standard metric provided by scoringutils.  If hubEvals eventually supports
#' other metrics, this function will need to be updated.
#'
#' @noRd
get_metric_name_to_output_type <- function(task_groups_w_target, metrics) {
  # the available output types for the target, based on the hub's tasks config
  available_output_types <- get_output_types(task_groups_w_target)

  # indicator of whether the target is ordinal
  target_is_ordinal <- is_target_ordinal(task_groups_w_target)

  # result is a data frame with 1 row for each metric
  # we populate the output type to use for each metric below
  result <- data.frame(
    metric = metrics,
    output_type = NA_character_
  )

  # manually handle interval coverage
  if ("quantile" %in% available_output_types) {
    result$output_type[grepl(
      pattern = "^interval_coverage_",
      x = metrics
    )] <- "quantile"
  }

  # other metrics
  for (output_type in available_output_types) {
    supported_metrics <- get_standard_metrics(output_type, target_is_ordinal)
    result$output_type[result$metric %in% supported_metrics] <- output_type
  }

  result
}


#' pmf metrics that scoringutils only exposes under ordinal dispatch (i.e. they
#' appear in `get_metrics(example_ordinal)` but not `get_metrics(example_nominal)`).
#' Used to decide when we have to resolve and forward `output_type_id_order` to
#' `score_model_out()`.
#' @noRd
ordinal_only_pmf_metrics <- function() {
  setdiff(
    names(scoringutils::get_metrics(scoringutils::example_ordinal)),
    names(scoringutils::get_metrics(scoringutils::example_nominal))
  )
}


#' Get the standard metrics that are supported for a given output type
#' @noRd
get_standard_metrics <- function(output_type, target_is_ordinal) {
  result <- switch(
    output_type,
    mean = "se_point",
    median = "ae_point",
    quantile = names(scoringutils::get_metrics(scoringutils::example_quantile)),
    pmf = if (target_is_ordinal) {
      names(scoringutils::get_metrics(scoringutils::example_ordinal))
    } else {
      names(scoringutils::get_metrics(scoringutils::example_nominal))
    },
    cdf = NULL,
    sample = NULL
  )

  result
}
