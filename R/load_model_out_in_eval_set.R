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
  task_groups <- get_model_tasks(hub_tasks_config, rounds_idx)
  task_groups_w_target <- filter_task_groups_to_target(task_groups, target_id)

  filter_to_target(hub_con, task_groups_w_target) |>
    filter_to_eval_set(
      eval_set,
      round_id_col = hub_tasks_config$rounds[[rounds_idx + 1]]$round_id,
      round_ids = hubUtils::get_round_ids(hub_tasks_config)
    )
}


#' Filter model output to the rows in an evaluation set
#'
#' @param model_out Model output rows: a data frame, or a lazy query on a hub
#' connection. Only rows are filtered, so the result has the columns of
#' `model_out`.
#' @param eval_set A list specifying the evaluation set, derived from the
#' eval_sets field of the predeval config.
#' @param round_id_col The round ID column: the `round_id` of the `rounds`
#' entry that `rounds_idx` selects.
#' @param round_ids The hub's round IDs, in order. `n_last` keeps the last
#' `n_last` of these, up to the latest round ID in `model_out`.
#'
#' @return A data frame of the rows of `model_out` in the evaluation set.
#' @noRd
filter_to_eval_set <- function(model_out, eval_set, round_id_col, round_ids) {
  # filter based on task id variables
  if ("task_filters" %in% names(eval_set)) {
    task_filters <- eval_set$task_filters
    for (task_id_var_name in names(task_filters)) {
      task_id_values <- task_filters[[task_id_var_name]]
      model_out <- dplyr::filter(
        model_out,
        .data[[task_id_var_name]] %in% task_id_values
      )
    }
  }

  # if eval_set doesn't specify any subsetting by rounds, return the full data
  no_limits <- !("round_filters" %in% names(eval_set))
  if (no_limits) {
    return(dplyr::collect(model_out))
  }

  round_filters <- eval_set$round_filters

  # if eval_set specifies a minimum round id, filter to that
  if ("min" %in% names(round_filters)) {
    model_out <- dplyr::filter(
      model_out,
      .data[[round_id_col]] >= round_filters$min
    )
  }

  # load the data
  model_out_tbl <- dplyr::collect(model_out)

  if ("n_last" %in% names(round_filters)) {
    # filter to the last n rounds
    max_present_round_id <- max(model_out_tbl[[round_id_col]])
    round_ids <- round_ids[round_ids <= max_present_round_id]
    round_ids <- utils::tail(round_ids, round_filters$n_last)
    model_out_tbl <- dplyr::filter(
      model_out_tbl,
      .data[[round_id_col]] %in% round_ids
    )
  }

  model_out_tbl
}
