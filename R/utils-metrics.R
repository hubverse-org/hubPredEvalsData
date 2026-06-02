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


#' Expand a metric vector with relative-skill entries.
#'
#' For each metric also listed in `relative_metrics`, splice a
#' `<metric>_scaled_relative_skill` entry in directly before it. This is the
#' single source of truth for the metric ordering shared by the `scores.csv`
#' columns (`order_relative_metric_cols()`) and the `predevals-options.json`
#' metric list (`generate_predevals_options()`).
#'
#' @param metrics Character vector of requested metric names.
#' @param relative_metrics Character vector of metrics that also get a scaled
#'   relative-skill column, or `NULL`.
#' @return `metrics` with relative-skill entries spliced in.
#' @noRd
expand_relative_skill_metrics <- function(metrics, relative_metrics) {
  purrr::map(metrics, function(metric) {
    if (metric %in% relative_metrics) {
      c(paste0(metric, "_scaled_relative_skill"), metric)
    } else {
      metric
    }
  }) |>
    unlist()
}


#' Expand a metric vector with transformed-scale entries.
#'
#' Composed after `expand_relative_skill_metrics()` to give the full metric
#' column order. For each entry whose base metric is transformable, the
#' transformed-scale name `<entry>__<label>` is placed directly after it when
#' `append` is `TRUE`, or replaces it when `append` is `FALSE` (matching
#' `generate_eval_data()`, which drops the natural scale then). The base metric
#' of a `<metric>_scaled_relative_skill` entry determines transformability.
#'
#' Transform-invariant metrics (interval coverage, bias) report on a single,
#' un-suffixed scale regardless of `append`: a strictly monotonic transform
#' preserves quantile ranks and the sign of forecast-vs-observation error,
#' so the transformed-scale column equals the natural-scale column. See #63
#' and `is_transform_invariant()`.
#'
#' @param expanded_metrics Character vector from `expand_relative_skill_metrics()`.
#' @param transformable_metrics Character vector of base metric names on a
#'   transformable output type.
#' @param label Transform label, used as the `__<label>` column suffix.
#' @param append If `TRUE`, transformed entries are interleaved alongside the
#'   natural-scale entries; if `FALSE`, they replace them.
#' @return `expanded_metrics` with transformed-scale entries interleaved.
#' @noRd
expand_transformed_metrics <- function(
  expanded_metrics,
  transformable_metrics,
  label,
  append
) {
  base_metrics <- sub("_scaled_relative_skill$", "", expanded_metrics)
  purrr::map2(expanded_metrics, base_metrics, function(metric, base) {
    if (!base %in% transformable_metrics || is_transform_invariant(base)) {
      return(metric)
    }
    transformed <- paste0(metric, "__", label)
    if (append) c(metric, transformed) else transformed
  }) |>
    unlist()
}


#' Identify metrics that are invariant under monotonic scale transforms.
#'
#' Two families of metrics are unchanged when forecasts and observations
#' undergo a strictly monotonic transform:
#'
#' - `interval_coverage_<n>`: interval containment depends only on the rank
#'   of the observation among the forecast quantiles, which a monotonic
#'   transform preserves.
#' - `bias`: scoringutils' quantile/sample bias is defined via the empirical
#'   CDF position of the observation in the forecast, also rank-based.
#'
#' The dashboard pipeline uses this predicate to drop the redundant
#' transformed-scale columns from `scores.csv` and `predevals-options.json`
#' so the same metric never appears twice. Matches the invariance set
#' documented in hubverse-org/hubDocs#464. See #63.
#'
#' @param metric Character vector of metric names.
#' @return Logical vector the same length as `metric`.
#' @noRd
is_transform_invariant <- function(metric) {
  grepl("^(interval_coverage_[0-9]+|bias)$", metric)
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
