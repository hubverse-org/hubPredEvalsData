#' Load model output data from a hub, filtering to a specified target and
#' evaluation set.
#'
#' @param hub_path A path to the hub.
#' @param target_id The target_id to filter to.
#' @param eval_set A list specifying the evaluation set, derived from the
#' eval_sets field of the predeval config.
#'
#' @return A data frame containing the model output data.
#' @noRd
load_model_out_in_eval_set <- function(hub_path, target_id, eval_set) {
  conn <- hubData::connect_hub(hub_path)

  # filter to the requested target_id
  hub_tasks_config <- hubUtils::read_config(hub_path, config = "tasks")
  round_ids <- hubUtils::get_round_ids(hub_tasks_config)
  task_groups <- hubUtils::get_round_model_tasks(hub_tasks_config, round_ids[1])
  task_groups_w_target <- filter_task_groups_to_target(task_groups, target_id)

  target_meta <- task_groups_w_target[[1]]$target_metadata[[1]]
  target_task_id_var_name <- names(target_meta$target_keys)
  target_task_id_value <- target_meta$target_keys[[target_task_id_var_name]]

  conn <- conn |>
    dplyr::filter(!!rlang::sym(target_task_id_var_name) == target_task_id_value)

  # filter based on task id variables
  if ("task_filters" %in% names(eval_set)) {
    task_filters <- eval_set$task_filters
    for (task_id_var_name in names(task_filters)) {
      task_id_values <- task_filters[[task_id_var_name]]
      conn <- conn |>
        dplyr::filter(!!rlang::sym(task_id_var_name) %in% task_id_values)
    }
  }

  # if eval_set doesn't specify any subsetting by rounds, return the full data
  no_limits <- !("round_filters" %in% names(eval_set))
  if (no_limits) {
    return(conn |> dplyr::collect())
  }

  round_filters <- eval_set$round_filters

  # if eval_set specifies a minimum round id, filter to that
  round_id_var_name <- hub_tasks_config[["rounds"]][[1]][["round_id"]]
  if ("min" %in% names(round_filters)) {
    conn <- conn |>
      dplyr::filter(!!rlang::sym(round_id_var_name) >= round_filters$min)
  }

  # load the data
  model_out_tbl <- conn |> dplyr::collect()

  if ("n_last" %in% names(round_filters)) {
    # filter to the last n rounds
    max_present_round_id <- max(model_out_tbl[[round_id_var_name]])
    round_ids <- round_ids[round_ids <= max_present_round_id]
    round_ids <- utils::tail(round_ids, round_filters$n_last)
    model_out_tbl <- model_out_tbl |>
      dplyr::filter(!!rlang::sym(round_id_var_name) %in% round_ids)
  }

  model_out_tbl
}
