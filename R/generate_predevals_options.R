#' Generate the contents of the `predevals-options.json` file
#'
#' Assembles the contents of the `predevals-options.json` file that
#' initialises the predevals dashboard. The dashboard reads this file on load
#' to build its menus and labelling: which targets and evaluation sets a user
#' can select, which metrics can be displayed for each target, which task-id
#' variables the scores can be disaggregated by, and the human-readable text
#' for task-id values. It is the dashboard's index of what can be shown; the
#' score values themselves come from the per-target `scores.csv` files written
#' by [generate_eval_data()].
#'
#' The result is the validated predevals config with each entry of `targets`
#' augmented with the metric and transform metadata the dashboard needs to
#' populate its metric selector:
#'
#' - `metrics`: the metric columns present in the target's `scores.csv`, in
#'   column order. A `<metric>_scaled_relative_skill` entry is spliced in
#'   before each metric listed in `relative_metrics`. When a transform applies,
#'   the transformed-scale `<metric>__<label>` columns are appended, or replace
#'   the natural-scale columns when `append: false`. This is the list the
#'   dashboard iterates to build its metric selector.
#' - `transform`: the resolved transform for the target (with
#'   `transform_defaults` inheritance applied), as a list with `fun`, `label`,
#'   `append` and a composed human-readable `description` the dashboard can
#'   show to explain the transformed scale to the user. The key is absent
#'   when no transform applies, including targets that opt out with
#'   `transform: false` and targets whose available output types are all
#'   non-transformable (where the transform is skipped at scoring time).
#'
#' The config is read via [read_predevals_config()], so the config schema and
#' transform validation run as a side effect. The caller decides where to
#' write the result.
#'
#' @inheritParams generate_eval_data
#'
#' @return The predevals config as a list, with each entry of `targets`
#'   augmented as described above.
#'
#' @export
generate_predevals_options <- function(hub_path, config_path) {
  config <- read_predevals_config(hub_path, config_path)
  config$targets <- purrr::map(
    config$targets,
    function(target) build_target_options(hub_path, config, target)
  )
  # `transform_defaults` is a config input that has been resolved into each
  # target's `transform`; drop it so the output carries only resolved
  # per-target transforms.
  config$transform_defaults <- NULL
  config
}


#' Build the options entry for a single config target.
#'
#' Expands the relative-skill metrics, resolves the effective transform, and,
#' when one applies, folds the transformed-scale columns into `metrics` and
#' attaches the `transform` metadata.
#'
#' @param target One entry from `config$targets`.
#' @inheritParams generate_predevals_options
#' @param config The full predevals config (used for `transform_defaults` and
#'   `rounds_idx`).
#' @noRd
build_target_options <- function(hub_path, config, target) {
  # get_metric_name_to_output_type() matches metrics by exact name, so it
  # needs the un-expanded metrics, not the `_scaled_relative_skill` names.
  raw_metrics <- target$metrics
  metrics <- expand_relative_skill_metrics(
    metrics = raw_metrics,
    relative_metrics = target$relative_metrics
  )
  target$metrics <- metrics

  transform <- resolve_target_transform(target, config$transform_defaults)
  # Drop the raw `transform` config input (a transform object, or the literal
  # `false` opt-out). The resolved block is re-attached below only when a
  # transform actually applies.
  target$transform <- NULL
  if (is.null(transform)) {
    return(target)
  }

  task_groups_w_target <- get_task_groups_w_target(
    hub_path,
    target$target_id,
    config$rounds_idx
  )
  metric_output_types <- get_metric_name_to_output_type(
    task_groups_w_target,
    raw_metrics
  )
  transformable_metrics <- metric_output_types$metric[
    metric_output_types$output_type %in% get_transformable_output_types()
  ]

  # No requested metric is on a transformable output type, so the transform is
  # silently skipped at scoring time (the config validator has already warned).
  # Report no transform, consistent with that.
  if (length(transformable_metrics) == 0L) {
    return(target)
  }

  label <- get_transform_label(transform)
  append <- isTRUE(transform$append %||% TRUE)
  # `metrics` mirrors the metric columns in `scores.csv`: each metric's
  # transformed-scale `__<label>` column interleaved after it (append = TRUE),
  # or replacing it (append = FALSE, where generate_eval_data() drops the
  # natural scale).
  target$metrics <- expand_transformed_metrics(
    expanded_metrics = metrics,
    transformable_metrics = transformable_metrics,
    label = label,
    append = append
  )
  target$transform <- list(
    fun = transform$fun,
    label = label,
    append = append,
    description = get_transform_description(transform)
  )
  target
}
