#' Load and validate a predevals config file
#'
#' @param hub_path A path to the hub.
#' @param config_path A path to a yaml file that specifies the configuration
#' options for the evaluation.
#'
#' @return A list of configuration options for the evaluation.
read_predevals_config <- function(hub_path, config_path) {
  tryCatch(
    {
      config <- yaml::read_yaml(config_path, eval.expr = FALSE)
    },
    error = function(e) {
      # This handler is used when an unrecoverable error is thrown while
      # attempting to read the config file: typically the file does not
      # exist or can't be parsed by read_yaml().
      cli::cli_abort(c(
        "Error reading predevals config file at {.val {config_path}}:",
        conditionMessage(e)
      ))
    }
  )

  validate_config(hub_path, config)

  config
}


#' Validate a predevals config object
#' @noRd
validate_config <- function(hub_path, config) {
  validate_config_vs_schema(config)
  validate_config_vs_hub_tasks(hub_path, config)
}


#' Validate a predevals config object against the config schema
#' @noRd
validate_config_vs_schema <- function(config) {
  config_json <- jsonlite::toJSON(config, auto_unbox = TRUE)
  schema_json <- load_schema_json(config)

  valid <- jsonvalidate::json_validate(
    config_json,
    schema_json,
    engine = "ajv",
    verbose = TRUE,
    greedy = TRUE
  )

  if (!valid) {
    msgs <- attr(valid, "errors") |>
      dplyr::transmute(
        m = dplyr::case_when(
          .data$keyword == "required" ~ paste(.data$message, "."),
          .data$keyword == "additionalProperties" ~ paste0(
            .data$message,
            "; saw unexpected property '",
            .data$params$additionalProperty,
            "'."
          ),
          TRUE ~ paste("-", .data$instancePath, .data$message, ".")
        )
      ) |>
      dplyr::pull(.data$m)
    names(msgs) <- rep("!", length(msgs))

    raise_config_error(msgs)
  }
}


#' Load the schema for a predevals config file, based on the schema version
#' specified in that config. It is not expected that the config has been
#' validated yet, other than that it can be read in by yaml::read_yaml. If the
#' config does not have a schema_version property or the value of that property
#' is malformatted, this function throws an error.
#'
#' @param config_json list of schema entries as returned by yaml::read_yaml
#'
#' @noRd
load_schema_json <- function(config) {
  if (!"schema_version" %in% names(config)) {
    raise_config_error(
      "The predevals config file is required to contain a `schema_version` property."
    )
  }

  if (
    !is.character(config$schema_version) || length(config$schema_version) != 1
  ) {
    raise_config_error(
      "The `schema_version` property of the config schema must be a string."
    )
  }

  schema_version <- hubUtils::extract_schema_version(config$schema_version)
  if (is.na(schema_version)) {
    raise_config_error(
      cli::format_inline(
        "Invalid `schema_version` property of the config schema. ",
        "Must be a URL to a version of the hubPredEvalsData config_schema.json file."
      )
    )
  }

  available_versions <- list.dirs(
    system.file("schema", package = "hubPredEvalsData"),
    full.names = FALSE,
    recursive = FALSE
  )
  if (!schema_version %in% available_versions) {
    raise_config_error(
      c(
        cli::format_inline(
          "Invalid predevals schema version."
        ),
        "x" = cli::format_inline(
          "Specified version: {.val {schema_version}}."
        ),
        "i" = cli::format_inline(
          "Valid versions: {.val {available_versions}}"
        )
      )
    )
  }

  minimum_version <- "v1.0.1"
  if (schema_version < minimum_version) {
    raise_config_error(
      c(
        cli::format_inline(
          "The predevals schema version is too old. Please update to the latest schema version."
        ),
        "x" = cli::format_inline(
          "Specified version: {.val {schema_version}}."
        ),
        "i" = cli::format_inline(
          "Minimum version: {.val {minimum_version}}"
        )
      )
    )
  }

  schema_path <- system.file(
    "schema",
    schema_version,
    "config_schema.json",
    package = "hubPredEvalsData"
  )

  schema_json <- jsonlite::read_json(schema_path, auto_unbox = TRUE) |>
    jsonlite::toJSON(auto_unbox = TRUE)

  schema_json
}


#' Validate a predevals config object against the hub tasks config
#' @noRd
validate_config_vs_hub_tasks <- function(hub_path, predevals_config) {
  hub_tasks_config <- hubUtils::read_config(hub_path, config = "tasks")
  task_id_names <- hubUtils::get_task_id_names(hub_tasks_config)

  # Validate rounds_idx is within bounds (0-based index from config)
  num_rounds <- length(hub_tasks_config[["rounds"]])
  if (predevals_config$rounds_idx >= num_rounds) {
    raise_config_error(
      cli::format_inline(
        "Invalid `rounds_idx` value {.val {predevals_config$rounds_idx}}. ",
        "Must be less than the number of rounds ({.val {num_rounds}})."
      )
    )
  }

  rounds_idx <- predevals_config$rounds_idx + 1 # Convert 0-based rounds_idx to 1-based for R indexing
  if (!hub_tasks_config[["rounds"]][[rounds_idx]][["round_id_from_variable"]]) {
    raise_config_error(
      "hubPredEvalsData only supports hubs with `round_id_from_variable` set to `true` in `tasks.json`."
    )
  }

  task_groups <- hub_tasks_config[["rounds"]][[rounds_idx]][["model_tasks"]]

  # checks for targets
  validate_config_targets(predevals_config, task_groups, task_id_names)

  # checks for per-target transforms (and inherited transform_defaults)
  validate_target_transforms(predevals_config, task_groups)

  # checks for eval_sets
  validate_config_eval_sets(
    predevals_config,
    hub_tasks_config,
    task_groups,
    task_id_names
  )

  # checks for task_id_text
  validate_config_task_id_text(predevals_config, task_groups, task_id_names)

  # checks for initial_sort_column
  validate_config_initial_sort_column(predevals_config)
}


#' Validate the targets in a predevals config object. For each target, check that:
#' - target_id in the predevals config appears in the hub tasks as a target_id
#' - metrics are valid for the available output types for that target
#' - disaggregate_by entries are task id variable names
#'
#' @noRd
validate_config_targets <- function(
  predevals_config,
  task_groups,
  task_id_names
) {
  for (target in predevals_config$targets) {
    target_id <- target$target_id

    # get task groups for this target
    task_groups_w_target <- filter_task_groups_to_target(task_groups, target_id)

    # check that target_id in the predevals config appears in the hub tasks
    if (length(task_groups_w_target) == 0) {
      raise_config_error(
        cli::format_inline(
          "Target id {.val {target_id}} not found in any task group."
        )
      )
    }

    # check that metrics are valid for the available output types
    metric_name_to_output_type <- get_metric_name_to_output_type(
      task_groups_w_target,
      target$metrics
    )
    unsupported_metrics <- setdiff(
      target$metrics,
      metric_name_to_output_type$metric[
        !is.na(metric_name_to_output_type$output_type)
      ]
    )

    if (length(unsupported_metrics) > 0) {
      available_output_types <- get_output_types(task_groups_w_target) # nolint: object_usage
      target_is_ordinal <- is_target_ordinal(task_groups_w_target)
      raise_config_error(
        c(
          cli::format_inline(
            "Requested scores for metrics that are incompatible with the ",
            "available output types for {.arg target_id} {.val {target_id}}."
          ),
          "i" = cli::format_inline(
            "Output type{?s}: {.val {available_output_types}}",
            ifelse(target_is_ordinal, " for ordinal target.", ".")
          ),
          "x" = cli::format_inline(
            "Unsupported metric{?s}: {.val {unsupported_metrics}}."
          )
        )
      )
    }

    # check that relative_metrics is a subset of metrics
    extra_relative_metrics <- setdiff(
      target$relative_metrics,
      target$metrics
    )
    if (length(extra_relative_metrics) > 0) {
      raise_config_error(
        c(
          cli::format_inline(
            "Requested relative metrics for metrics that were not requested ",
            "for {.arg target_id} {.val {target_id}}."
          ),
          "i" = cli::format_inline(
            "Requested metric{?s}: {.val {target$metrics}}."
          ),
          "x" = cli::format_inline(
            "Relative metric{?s} not found in the requested metrics: ",
            "{.val {extra_relative_metrics}}."
          )
        )
      )
    }

    # check that disaggregate_by are task id variable names
    extra_disaggregate_by <- setdiff(
      target$disaggregate_by,
      task_id_names
    )
    if (length(extra_disaggregate_by) > 0) {
      raise_config_error(
        cli::format_inline(
          "Disaggregate by variable{?s} {.val {extra_disaggregate_by}} not ",
          "found in the hub task id variables."
        )
      )
    }
  }
}


#' Validate transform configuration against the hub tasks config.
#'
#' Validates the `args` of any transform config — both top-level
#' `transform_defaults` and any per-target `transform` — against the formals of
#' the chosen transform function.
#'
#' Additionally, for each target:
#' - If the target's available output types are all non-transformable (e.g.
#'   pmf-only) and the target has an explicit transform config, raise an error
#'   (likely a misconfiguration).
#' - If the target's available output types are all non-transformable and no
#'   explicit `transform` is set but `transform_defaults` is configured,
#'   warn that the inherited transform will be silently skipped at scoring
#'   time.
#'
#' @noRd
validate_target_transforms <- function(predevals_config, task_groups) {
  transform_defaults <- predevals_config$transform_defaults

  # validate transform_defaults args up-front so the error is raised even if
  # every target overrides or opts out
  if (!is.null(transform_defaults)) {
    validate_transform_args(transform_defaults, target_id = NULL)
  }

  for (target in predevals_config$targets) {
    validate_target_transform(target, task_groups, transform_defaults)
  }
}


#' Validate the transform configuration for a single target.
#'
#' Args of an explicit per-target `transform` are checked against the formals
#' of the chosen function. Then, if a transform would actually be applied to
#' the target (explicit or inherited), the target's available output types are
#' checked: an explicit transform on a target with no transformable output
#' types is an error; an inherited `transform_defaults` on the same is a
#' warning (the transform is silently skipped at scoring time).
#'
#' @importFrom rlang %||%
#' @noRd
validate_target_transform <- function(target, task_groups, transform_defaults) {
  target_transform <- target$transform

  # explicit opt-out: nothing to validate
  if (isFALSE(target_transform)) {
    return()
  }

  # determine whether any transform actually applies to this target
  effective_transform <- target_transform %||% transform_defaults
  if (is.null(effective_transform)) {
    return()
  }

  # explicit per-target transform set: validate its args
  if (!is.null(target_transform)) {
    validate_transform_args(target_transform, target$target_id)
  }

  # check the target's output types support transformation
  validate_transform_output_types(
    target$target_id,
    task_groups,
    target_transform
  )
}


#' Validate that a target's available output types include at least one
#' transformable output type.
#'
#' Called only when an effective transform applies to the target. If none of
#' the target's available output types support transformation, raises an
#' error (when the transform is explicitly configured on the target) or warns
#' (when the transform is inherited from `transform_defaults` and would be
#' silently skipped at scoring time).
#'
#' @param target_id The target id, used for messages and to look up output
#'   types.
#' @param task_groups Hub task groups, as produced by `get_task_groups()`.
#' @param target_transform The per-target `transform` value (a list when
#'   explicit, `NULL` when inherited from `transform_defaults`).
#' @noRd
validate_transform_output_types <- function(
  target_id,
  task_groups,
  target_transform
) {
  task_groups_w_target <- filter_task_groups_to_target(task_groups, target_id)
  available_output_types <- get_output_types(task_groups_w_target)
  transformable_output_types <- get_transformable_output_types()

  if (any(available_output_types %in% transformable_output_types)) {
    return()
  }

  if (!is.null(target_transform)) {
    # explicit transform on a fully non-transformable target -> error
    raise_config_error(
      c(
        cli::format_inline(
          "Invalid {.field transform} for target {.val {target_id}}."
        ),
        "x" = cli::format_inline(
          "None of the target's available output types ({.val {available_output_types}}) support transformation."
        ),
        "i" = cli::format_inline(
          "Transformable output type{?s}: {.val {transformable_output_types}}."
        )
      )
    )
  } else {
    # inherited transform_defaults on a fully non-transformable target -> warn
    cli::cli_warn(
      c(
        "Inherited {.field transform_defaults} cannot apply to target {.val {target_id}}.",
        "!" = "None of the target's available output types ({.val {available_output_types}}) support transformation.",
        "i" = "The transform will be skipped at scoring time.",
        "i" = "To silence this warning, set {.code transform: false} on this target."
      )
    )
  }
}


#' Validate that the `args` of a transform config are accepted by the
#' referenced transform function.
#'
#' Compares `names(transform$args)` against `formalArgs(func)`, excluding the
#' data argument `x`.
#'
#' @param transform A transform config list (must contain `fun`).
#' @param target_id Target id for error context, or NULL when validating
#'   `transform_defaults`.
#' @noRd
validate_transform_args <- function(transform, target_id) {
  func_name <- transform[["fun"]]
  args <- transform[["args"]]

  if (is.null(args) || length(args) == 0L) {
    return()
  }

  func <- get_transform_function(func_name)
  allowed_args <- setdiff(formalArgs(func), "x")

  extra_args <- setdiff(names(args), allowed_args)
  if (length(extra_args) > 0) {
    main_msg <- if (is.null(target_id)) {
      cli::format_inline(
        "Invalid {.field args} for {.field transform_defaults}."
      )
    } else {
      cli::format_inline(
        "Invalid {.field args} for {.field transform} on target {.val {target_id}}."
      )
    }
    raise_config_error(
      c(
        main_msg,
        "x" = cli::format_inline(
          "Transform function {.val {func_name}} does not accept argument{?s} ",
          "{.val {extra_args}}."
        ),
        "i" = cli::format_inline(
          "Allowed argument{?s}: {.val {allowed_args}}."
        )
      )
    )
  }
}


#' Validate the eval_sets in a predevals config object
#'  - check that min specified in predevals config is a valid round_id
#'    for the hub
#'  - check that any entries in task_filters are valid task id variables
#'  - check that for each task id variable in task_filters, specified values are valid values
#'    for that task id as specified in the hub's config
#'
#' @noRd
validate_config_eval_sets <- function(
  predevals_config,
  hub_tasks_config,
  task_groups,
  task_id_names
) {
  hub_round_ids <- hubUtils::get_round_ids(hub_tasks_config)
  for (eval_set in predevals_config$eval_sets) {
    # check that min is a valid round_id
    # only do this check if eval_set$round_filters$min is specified
    round_filters <- eval_set$round_filters
    if (
      "min" %in% names(round_filters) && !round_filters$min %in% hub_round_ids
    ) {
      raise_config_error(
        cli::format_inline(
          "Minimum round id {.val {round_filters$min}} for evaluation ",
          "set is not a valid round id for the hub."
        )
      )
    }

    # check that any entries in task_filters are valid task id variables
    task_filters <- eval_set$task_filters
    extra_set_filter_names <- setdiff(
      names(task_filters),
      task_id_names
    )
    if (length(extra_set_filter_names) > 0) {
      raise_config_error(
        cli::format_inline(
          "Specified task filters based on task id variable{?s} {.val {extra_set_filter_names}} ",
          "that {?is/are} not found in the hub task id variables."
        )
      )
    }

    # check that for any task id variables, specified values are valid values
    # for that task id as specified in the hub's config
    task_ids_filtered_on <- names(task_filters)
    error_messages <- purrr::map(
      task_ids_filtered_on,
      function(task_id_name) {
        extra_set_filter_values <- setdiff(
          task_filters[[task_id_name]],
          get_task_id_values(task_groups, task_id_name)
        )
        if (length(extra_set_filter_values) == 0) {
          NULL
        } else {
          cli::format_inline(
            "Evaluation set specified invalid filter values on task id variable {.val {task_id_name}}: ",
            "{.val {extra_set_filter_values}}"
          )
        }
      }
    ) |>
      unlist()

    if (length(error_messages) > 0) {
      raise_config_error(error_messages)
    }
  }
}


#' Validate the task_id_text in a predevals config object
#' - check that all task_id_text items are valid task id variable names
#' - check that all values of the task id variable in the hub appear as task_id_text item keys
#'
#' @noRd
validate_config_task_id_text <- function(
  predevals_config,
  task_groups,
  task_id_names
) {
  # all task_id_text items must be valid task id variable names
  extra_task_id_text_names <- setdiff(
    names(predevals_config$task_id_text),
    task_id_names
  )
  if (length(extra_task_id_text_names) > 0) {
    raise_config_error(
      cli::format_inline(
        "Specified `task_id_text` for task id variable{?s} {.val {extra_task_id_text_names}} ",
        "that {?is/are} not found in the hub task id variables."
      )
    )
  }

  # all values of the task id variable in the hub must appear as task_id_text item keys
  for (i in seq_along(predevals_config$task_id_text)) {
    task_id_text_item <- predevals_config$task_id_text[[i]]
    task_id_name <- names(predevals_config$task_id_text)[i]
    hub_task_id_values <- get_task_id_values(task_groups, task_id_name)

    missing_task_id_text_values <- setdiff(
      hub_task_id_values,
      names(task_id_text_item)
    )

    # check that task_id_name is a valid task id variable name
    if (length(missing_task_id_text_values) > 0) {
      raise_config_error(
        cli::format_inline(
          "`task_id_text` must contain text values for all possible levels of task id variables. ",
          "For task id variable {.val {task_id_name}}, missing the following values: ",
          "{.val {missing_task_id_text_values}}"
        )
      )
    }
  }
}


#' Validate the initial_sort_column in a predevals config object.
#' Checks that the value, if specified, is one of the columns that appear in
#' the output scores table for at least one target. Valid columns are the union
#' across all targets (not the intersection), because the downstream predevals
#' app handles a missing sort column at render time and falls back gracefully
#' when a configured column is absent from a particular target's scores table.
#' @noRd
validate_config_initial_sort_column <- function(predevals_config) {
  initial_sort_column <- predevals_config$initial_sort_column
  if (is.null(initial_sort_column)) {
    return()
  }

  valid_columns <- c("model_id", "n")
  for (target in predevals_config$targets) {
    metrics <- target$metrics
    valid_columns <- c(valid_columns, metrics)
    if (!is.null(target$relative_metrics)) {
      valid_columns <- c(
        valid_columns,
        paste0(target$relative_metrics, "_scaled_relative_skill")
      )
    }
    if (!is.null(target$disaggregate_by)) {
      valid_columns <- c(valid_columns, target$disaggregate_by)
    }
  }
  valid_columns <- unique(valid_columns)

  if (!initial_sort_column %in% valid_columns) {
    raise_config_error(
      c(
        cli::format_inline(
          "Invalid `initial_sort_column` value {.val {initial_sort_column}}."
        ),
        "i" = cli::format_inline(
          "Must be one of the output scores table columns."
        ),
        "x" = cli::format_inline(
          "Valid columns: {.val {valid_columns}}."
        )
      )
    )
  }
}


#' Raise an error related to the predevals config file
#' @noRd
raise_config_error <- function(msgs) {
  call <- rlang::caller_call()
  if (!is.null(call)) {
    call <- rlang::call_name(call)
  }

  cli::cli_abort(c(
    "Error in predevals config file:",
    msgs
  ))
}
