#' Get the task groups from a hub's tasks config that contain a target_id, and
#' subset the target_metadata to just the entry for the target_id.
#'
#' @param hub_path A path to the hub.
#' @param target_id The target_id to filter to.
#' @param rounds_idx 0-based index of the rounds entry to use.
#'
#' @noRd
get_task_groups_w_target <- function(hub_path, target_id, rounds_idx) {
  hub_tasks_config <- hubUtils::read_config(hub_path, config = "tasks")
  round_ids <- hubUtils::get_round_ids(hub_tasks_config)
  task_groups <- hubUtils::get_round_model_tasks(hub_tasks_config, round_ids[rounds_idx + 1])
  task_groups_w_target <- filter_task_groups_to_target(task_groups, target_id)

  task_groups_w_target
}


#' Filter task groups from a hub's tasks config to those that contain a target_id.
#' Additionally, subset the target_metadata to just the entry for the target_id.
#'
#' @noRd
filter_task_groups_to_target <- function(task_groups, target_id) {
  # For each task group, subset the target_metadata to just the entry for the target_id
  # If the target_id is not in the task group, the target_metadata will be empty
  task_groups <- purrr::map(
    task_groups,
    function(task_group) {
      task_group$target_metadata <- purrr::keep(task_group$target_metadata,
                                                ~ .x$target_id == target_id)
      task_group
    }
  )

  # Remove task groups that don't contain the target_id
  task_groups <- purrr::keep(task_groups, ~ length(.x$target_metadata) > 0)

  task_groups
}


#' get a vector of all optional and required values for a given task id variable,
#' collected across all task groups
#'
#' @noRd
get_task_id_values <- function(task_groups, task_id_name) {
  task_id_values <- purrr::map(
    task_groups,
    function(task_group) {
      task_group$task_ids[[task_id_name]]
    }
  ) |>
    unlist() |>
    unique()

  task_id_values
}


#' Get a character vector of all output types across all task groups
#' @noRd
get_output_types <- function(task_groups) {
  output_types <- purrr::map(
    task_groups,
    function(task_group) names(task_group[["output_type"]])
  ) |>
    unlist() |>
    unique()

  output_types
}


#' Get a boolean indicating whether the target is ordinal
#' @noRd
is_target_ordinal <- function(task_groups_w_target) {
  # The task_groups_w_target has been filtered to a single target,
  # so we can just check the target_type of the first entry
  target_type <- task_groups_w_target[[1]]$target_metadata[[1]]$target_type

  target_type == "ordinal"
}


#' Get the output type id values for a given output type. The output type may
#' appear in multiple task groups, and the output type id values in those groups
#' may differ as long as there is one group that has all of the output type id
#' values.
#' @noRd
get_output_type_ids_for_type <- function(task_groups, output_type) {
  output_type_ids_by_group <- purrr::map(
    task_groups,
    function(task_group) {
      task_group$output_type[[output_type]]$output_type_id
    }
  )

  # Small groups should contain subsets of the largest group, so this is our reference.
  output_type_ids <- output_type_ids_by_group[[which.max(lengths(output_type_ids_by_group))]]

  # check that the output type id values in each group are a (possibly improper)
  # subset of the output type id values in the group with the most values, in
  # the same order
  for (i in seq_along(output_type_ids_by_group)) {
    output_type_ids_group <- output_type_ids_by_group[[i]]

    # if output_type_ids_group has any entries that are not in output_type_ids,
    # raise an error
    if (any(!output_type_ids_group %in% output_type_ids)) {
      cli::cli_abort(
        "In hub's tasks.json, output type ids for output type {.val {output_type}}
         have different values across task groups."
      )
    }

    # if output_type_ids and output_type_ids_group have some entries in common
    # but order differs, raise an error
    output_type_ids_subset <- output_type_ids[output_type_ids %in% output_type_ids_group]
    if (!identical(output_type_ids_subset, output_type_ids_group)) {
      cli::cli_abort(
        "In hub's tasks.json, output type ids for output type {.val {output_type}}
         have different order across task groups."
      )
    }
  }

  output_type_ids
}
