#' Generate evaluation data for a hub
#'
#' Scores each target configured in the predevals config against its oracle
#' data and writes wide-format score tables to disk.
#'
#' @param hub_path A path to the hub.
#' @param config_path A path to a yaml file that specifies the configuration
#' options for the evaluation.
#' @param out_path The directory to write the evaluation data to.
#' @param oracle_output A data frame of oracle output to use for the evaluation.
#'
#' @section Output:
#' For each `(target, eval_set, disaggregation)` requested in the config, a
#' `scores.csv` is written under `out_path/<target_id>/<eval_set_name>[/<by>]/`
#' in wide format, with one row per model per disaggregation key.
#'
#' When a target has a configured transform, transformed-scale metrics appear
#' as `<metric>__<label>`-suffixed columns (e.g. `wis__log`) alongside the
#' natural-scale columns. Setting `append: false` emits only the suffixed
#' columns.
#'
#' For the full configuration schema, see the JSON Schema files installed
#' with the package under
#' `system.file("schema", package = "hubPredEvalsData")`.
#'
#' @export
generate_eval_data <- function(hub_path, config_path, out_path, oracle_output) {
  config <- read_predevals_config(hub_path, config_path)
  for (target in config$targets) {
    generate_target_eval_data(hub_path, config, out_path, oracle_output, target)
  }
}


#' Generate evaluation data for a target
#'
#' @inheritParams generate_eval_data
#' @param config The configuration options for the evaluation.
#' @param target The target to generate evaluation data for. This is one object
#' from the list of targets in the config, with properties "target_id",
#' "metrics", and "disaggregate_by".
#'
#' @noRd
generate_target_eval_data <- function(
  hub_path,
  config,
  out_path,
  oracle_output,
  target
) {
  target_id <- target$target_id
  metrics <- target$metrics
  # if relative_metrics and baseline are not provided, the are NULL
  relative_metrics <- target$relative_metrics
  baseline <- target$baseline
  # adding `NULL` at the beginning will calculate overall scores
  disaggregate_by <- c(list(NULL), as.list(target$disaggregate_by))
  eval_sets <- config$eval_sets
  transform <- resolve_target_transform(target, config$transform_defaults)

  task_groups_w_target <- get_task_groups_w_target(
    hub_path,
    target_id,
    config$rounds_idx
  )
  metric_name_to_output_type <- get_metric_name_to_output_type(
    task_groups_w_target,
    metrics
  )

  for (eval_set in eval_sets) {
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path,
      target$target_id,
      eval_set,
      config$rounds_idx
    )
    if (nrow(model_out_tbl) == 0) {
      cli::cli_inform(
        "No model output data found for target {.val {target_id}}
         in evaluation set {.val {eval_set$eval_set_name}}."
      )
      next
    }

    # calculate overall scores followed by scores disaggregated by a task ID variable.
    for (by in disaggregate_by) {
      get_and_save_scores(
        model_out_tbl = model_out_tbl,
        oracle_output = oracle_output,
        metric_name_to_output_type = metric_name_to_output_type,
        relative_metrics = relative_metrics,
        baseline = baseline,
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


#' Get and save scores for a target in a given evaluation set,
#' collecting across different output types as necessary.
#' Scores are saved in .csv files in subdirectorys under out_path with one of
#' two structures:
#' - If by is NULL, the scores are saved in
#' out_path/target_id/eval_set_name/scores.csv
#' - If by is not NULL, the scores are saved in
#' out_path/target_id/eval_set_name/by/scores.csv
#' @noRd
get_and_save_scores <- function(
  model_out_tbl,
  oracle_output,
  metric_name_to_output_type,
  relative_metrics,
  baseline,
  target_id,
  eval_set_name,
  by,
  out_path,
  transform,
  task_groups_w_target
) {
  # Iterate over the output types and calculate scores for each
  scores <- purrr::map(
    unique(metric_name_to_output_type$output_type),
    ~ get_scores_for_output_type(
      model_out_tbl = model_out_tbl,
      oracle_output = oracle_output,
      metric_name_to_output_type = metric_name_to_output_type,
      relative_metrics = relative_metrics,
      baseline = baseline,
      target_id = target_id,
      eval_set_name = eval_set_name,
      by = by,
      output_type = .x,
      transform = transform,
      task_groups_w_target = task_groups_w_target
    )
  ) |>
    purrr::reduce(dplyr::left_join, by = c("model_id", by))

  # Add the number of prediction tasks that were scored within each model/by group
  # After dropping output_type, output_type_id, and value, we are left with model_id
  # and task id columns.  The number of prediction tasks is the number of distinct
  # rows within each group.
  group_cols <- c("model_id", by)
  n_tasks_by_group <- model_out_tbl |>
    dplyr::select(
      !dplyr::all_of(c("output_type", "output_type_id", "value"))
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::distinct() |>
    dplyr::summarize(n = dplyr::n())
  scores <- scores |> dplyr::left_join(n_tasks_by_group, by = group_cols)

  # Save the scores to a .csv file
  target_set_by_out_path <- file.path(out_path, target_id, eval_set_name)
  if (!is.null(by)) {
    target_set_by_out_path <- file.path(target_set_by_out_path, by)
  }
  if (!dir.exists(target_set_by_out_path)) {
    dir.create(target_set_by_out_path, recursive = TRUE)
  }
  utils::write.csv(
    scores,
    file = file.path(target_set_by_out_path, "scores.csv"),
    row.names = FALSE
  )
}


#' Get scores for a target in a given evaluation set for a specific output type.
#'
#' If `transform` is set and the output type is transformable
#' (see `get_transformable_output_types()`), scores are computed with the
#' scale transformation applied. The hubEvals long-format output (with a
#' `scale` column when `append = TRUE`) is pivoted to wide format here so that
#' transformed-scale metrics become label-prefixed columns alongside their
#' natural-scale counterparts.
#' @noRd
get_scores_for_output_type <- function(
  model_out_tbl,
  oracle_output,
  metric_name_to_output_type,
  relative_metrics,
  baseline,
  target_id,
  eval_set_name,
  by,
  output_type,
  transform,
  task_groups_w_target
) {
  metrics <- metric_name_to_output_type$metric[
    metric_name_to_output_type$output_type == output_type
  ]
  if (!is.null(relative_metrics)) {
    relative_metrics <- relative_metrics[relative_metrics %in% metrics]
  }

  apply_transform <- !is.null(transform) &&
    output_type %in% get_transformable_output_types()
  transform_append <- apply_transform && isTRUE(transform$append %||% TRUE)
  transform_label <- if (apply_transform) get_transform_label(transform)
  # When `append = TRUE`, scoringutils emits both natural- and transformed-scale
  # rows keyed by a `scale` column. We must include `"scale"` in `by` so
  # hubEvals' summarise step (which averages everything not in `by`) doesn't
  # collapse the two scales together. We then pivot that long format to wide.
  # With `append = FALSE`, only transformed rows are produced and no `scale`
  # column is emitted, so there's nothing to keep separated.
  score_by <- c("model_id", by, if (transform_append) "scale")
  score_args <- list(
    model_out_tbl = model_out_tbl |>
      dplyr::filter(.data[["output_type"]] == !!output_type),
    oracle_output = oracle_output,
    metrics = metrics,
    relative_metrics = relative_metrics,
    baseline = baseline,
    by = score_by
  )
  # Ordinal pmf with a metric that requires ordinal dispatch (e.g. rps): pass
  # the ordered level vector so scoringutils dispatches as forecast_ordinal
  # rather than forecast_nominal. log_score works under either dispatch with
  # identical results, so we skip the lookup when only log_score is requested.
  if (
    output_type == "pmf" &&
      is_target_ordinal(task_groups_w_target) &&
      any(metrics %in% ordinal_only_pmf_metrics()) # nolint: object_usage
  ) {
    score_args$output_type_id_order <- get_output_type_ids_for_type(
      task_groups_w_target,
      "pmf"
    )
  }
  if (apply_transform) {
    score_args$transform <- get_transform_function(transform$fun)
    score_args$transform_append <- transform_append
    score_args$transform_label <- transform_label
    score_args <- c(score_args, transform$args)
  }
  scores <- do.call(hubEvals::score_model_out, score_args)

  scores <- order_relative_metric_cols(
    scores,
    score_by,
    relative_metrics,
    metrics
  )

  if (apply_transform) {
    scores <- pivot_transformed_scores(
      scores,
      by = by,
      label = transform_label,
      append = transform_append
    )
  }

  scores
}


#' Drop the unscaled relative-skill columns and reorder metric columns so each
#' `<metric>_scaled_relative_skill` column appears directly before its base
#' metric column. Returns `scores` unchanged when `relative_metrics` is `NULL`.
#' @noRd
order_relative_metric_cols <- function(
  scores,
  id_cols,
  relative_metrics,
  metrics
) {
  if (is.null(relative_metrics)) {
    return(scores)
  }

  rel_skill_colnames <- paste0(relative_metrics, "_relative_skill")
  scores <- dplyr::select(scores, !dplyr::all_of(rel_skill_colnames))

  ordered_metric_cols <- purrr::map(
    metrics,
    function(metric) {
      c(
        if (metric %in% relative_metrics) {
          paste0(metric, "_scaled_relative_skill")
        } else {
          NULL
        },
        metric
      )
    }
  ) |>
    unlist()

  dplyr::select(scores, dplyr::all_of(c(id_cols, ordered_metric_cols)))
}


#' Pivot transformed-scale scores into label-suffixed wide-format columns.
#'
#' For `append = TRUE`, hubEvals emits one row per `(model_id, by..., scale)`
#' with `scale` being either `"natural"` or the transform label. We split on
#' `scale`, suffix the transformed-scale metric columns with `"__<label>"`,
#' and left-join back to the natural-scale rows so a single row per
#' `(model_id, by...)` carries both scales.
#'
#' For `append = FALSE`, only transformed-scale rows are produced (no `scale`
#' column) and we simply rename all metric columns with the `"__<label>"`
#' suffix.
#'
#' The double-underscore separator lets downstream tools split a column name
#' into (base-metric, transform-label) unambiguously, since no current metric
#' name contains `"__"`.
#' @noRd
pivot_transformed_scores <- function(scores, by, label, append) {
  id_cols <- c("model_id", by)
  if (!append) {
    return(suffix_metric_cols(scores, id_cols, label))
  }

  is_natural <- scores$scale == "natural"
  keep_cols <- setdiff(names(scores), "scale")
  natural <- scores[is_natural, keep_cols, drop = FALSE]
  transformed <- suffix_metric_cols(
    scores[!is_natural, keep_cols, drop = FALSE],
    id_cols,
    label
  )
  dplyr::left_join(natural, transformed, by = id_cols)
}


#' Rename non-id columns in `df` by suffixing them with `"__<label>"`.
#' @noRd
suffix_metric_cols <- function(df, id_cols, label) {
  is_metric <- !names(df) %in% id_cols
  names(df)[is_metric] <- paste0(names(df)[is_metric], "__", label)
  df
}
