#' Generate evaluation data for a hub
#'
#' @param hub_path A path to the hub.
#' @param config_path A path to a yaml file that specifies the configuration
#' options for the evaluation.
#' @param out_path The directory to write the evaluation data to.
#' @param oracle_output A data frame of oracle output to use for the evaluation.
#'
#' @export
generate_eval_data <- function(hub_path,
                               config_path,
                               out_path,
                               oracle_output) {
  config <- read_config(hub_path, config_path)
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
generate_target_eval_data <- function(hub_path,
                                      config,
                                      out_path,
                                      oracle_output,
                                      target) {
  target_id <- target$target_id
  metrics <- target$metrics
  # if relative_metrics and baseline are not provided, the are NULL
  relative_metrics <- target$relative_metrics
  baseline <- target$baseline
  # adding `NULL` at the beginning will calculate overall scores
  disaggregate_by <- c(list(NULL), as.list(target$disaggregate_by))
  eval_sets <- config$eval_sets

  task_groups_w_target <- get_task_groups_w_target(hub_path, target_id)
  metric_name_to_output_type <- get_metric_name_to_output_type(task_groups_w_target, metrics)

  for (eval_set in eval_sets) {
    model_out_tbl <- load_model_out_in_eval_set(hub_path, target$target_id, eval_set)
    if (nrow(model_out_tbl) == 0) {
      cli::cli_warn(
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
        out_path = out_path
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
get_and_save_scores <- function(model_out_tbl, oracle_output, metric_name_to_output_type,
                                relative_metrics, baseline,
                                target_id, eval_set_name, by,
                                out_path) {
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
      output_type = .x
    )
  ) |>
    purrr::reduce(dplyr::left_join, by = c("model_id", by))

  # Add the number of prediction tasks that were scored within each model/by group
  # After dropping output_type, output_type_id, and value, we are left with model_id
  # and task id columns.  The number of prediction tasks is the number of distinct
  # rows within each group.
  group_cols <- c("model_id", by)
  n_tasks_by_group <- model_out_tbl |>
    dplyr::select(!dplyr::all_of(c("output_type", "output_type_id", "value"))) |>
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
  utils::write.csv(scores,
                   file = file.path(target_set_by_out_path, "scores.csv"),
                   row.names = FALSE)
}


#' Get scores for a target in a given evaluation set for a specific output type.
#' @noRd
get_scores_for_output_type <- function(model_out_tbl, oracle_output, metric_name_to_output_type,
                                       relative_metrics, baseline,
                                       target_id, eval_set_name, by,
                                       output_type) {
  metrics <- metric_name_to_output_type$metric[
    metric_name_to_output_type$output_type == output_type
  ]
  if (!is.null(relative_metrics)) {
    relative_metrics <- relative_metrics[relative_metrics %in% metrics]
  }
  scores <- hubEvals::score_model_out(
    model_out_tbl = model_out_tbl |> dplyr::filter(.data[["output_type"]] == !!output_type),
    oracle_output = oracle_output,
    metrics = metrics,
    relative_metrics = relative_metrics,
    baseline = baseline,
    by = c("model_id", by)
  )

  if (!is.null(relative_metrics)) {
    # Return only the scaled relative metrics, not the unscaled ones
    rel_skill_colnames <- paste0(relative_metrics, "_relative_skill")
    scores <- dplyr::select(scores, !dplyr::all_of(rel_skill_colnames))

    # Place scaled relative metric columns before corresponding metric columns
    # relative_metrics is a subset of metrics
    ordered_metric_cols <- purrr::map(
      metrics,
      function(metric) {
        c(
          if (metric %in% relative_metrics) paste0(metric, "_scaled_relative_skill") else NULL,
          metric
        )
      }
    ) |>
      unlist()
    scores <- scores |>
      dplyr::select(dplyr::all_of(
        c("model_id", by, ordered_metric_cols)
      ))
  }

  scores
}
