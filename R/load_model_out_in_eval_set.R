#' Load model output data from a hub, filtering to a specified target and
#' evaluation set.
#'
#' @param hub_path A path to the hub.
#' @param target_id The target_id to filter to.
#' @param eval_set A list specifying the evaluation set, derived from the
#' eval_sets field of the predeval config.
#' @param rounds_idx 0-based index of the rounds entry to use.
#' @param hub_con Optional hub connection, as returned by
#' [hubData::connect_hub()]. When `NULL` (the default), a connection is opened
#' from `hub_path`.
#'
#' @return A data frame containing the model output data.
#' @noRd
load_model_out_in_eval_set <- function(
  hub_path,
  target_id,
  eval_set,
  rounds_idx,
  hub_con = NULL
) {
  if (is.null(hub_con)) {
    hub_con <- hubData::connect_hub(hub_path)
  }
  hub_tasks_config <- hubUtils::read_config(hub_path, config = "tasks")
  round_ids <- hubUtils::get_round_ids(hub_tasks_config)
  task_groups <- get_model_tasks(hub_tasks_config, rounds_idx)
  task_groups_w_target <- filter_task_groups_to_target(task_groups, target_id)

  hub_con <- filter_to_target(hub_con, task_groups_w_target)

  # filter based on task id variables
  if ("task_filters" %in% names(eval_set)) {
    task_filters <- eval_set$task_filters
    for (task_id_var_name in names(task_filters)) {
      task_id_values <- task_filters[[task_id_var_name]]
      hub_con <- dplyr::filter(
        hub_con,
        .data[[task_id_var_name]] %in% task_id_values
      )
    }
  }

  # if eval_set doesn't specify any subsetting by rounds, return the full data
  no_limits <- !("round_filters" %in% names(eval_set))
  if (no_limits) {
    return(dplyr::collect(hub_con))
  }

  round_filters <- eval_set$round_filters

  # if eval_set specifies a minimum round id, filter to that
  round_id_var_name <- hub_tasks_config[["rounds"]][[rounds_idx + 1]][[
    "round_id"
  ]]
  if ("min" %in% names(round_filters)) {
    hub_con <- dplyr::filter(
      hub_con,
      .data[[round_id_var_name]] >= round_filters$min
    )
  }

  # load the data
  model_out_tbl <- dplyr::collect(hub_con)

  if ("n_last" %in% names(round_filters)) {
    # filter to the last n rounds
    max_present_round_id <- max(model_out_tbl[[round_id_var_name]])
    round_ids <- round_ids[round_ids <= max_present_round_id]
    round_ids <- utils::tail(round_ids, round_filters$n_last)
    model_out_tbl <- dplyr::filter(
      model_out_tbl,
      .data[[round_id_var_name]] %in% round_ids
    )
  }

  model_out_tbl
}
