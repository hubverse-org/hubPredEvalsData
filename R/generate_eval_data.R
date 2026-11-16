#' Generate evaluation data for a hub
#'
#' Scores each target configured in the predevals config against its oracle
#' data and writes wide-format score tables to disk.
#'
#' @param hub_path A path to the hub.
#' @param config_path A path to a yaml file that specifies the configuration
#' options for the evaluation.
#' @param out_path The directory to write the evaluation data to.
#' @param oracle_output Optional data frame of oracle output to use for the
#' evaluation. When `NULL` (the default), oracle output is discovered from
#' `hub_path` via [hubData::connect_target_oracle_output()]. Supplying a
#' pre-loaded data frame remains supported for back-compat with callers
#' that load oracle data themselves.
#' @param hub_con Optional hub connection, as returned by
#' [hubData::connect_hub()]. When `NULL` (the default), a connection is opened
#' from `hub_path` and reused for every target and evaluation set.
#'
#' @section Output:
#' For each `(target, eval_set, disaggregation)` requested in the config, a
#' `scores.csv` is written under `out_path/<target_id>/<eval_set_name>[/<by>]/`
#' in wide format, with one row per model per disaggregation key.
#'
#' When a target has a configured transform, transformed-scale metrics appear
#' as `<metric>__<label>`-suffixed columns (e.g. `wis__log`) alongside the
#' natural-scale columns. Setting `append: false` emits only the suffixed
#' columns. Transform-invariant metrics (`interval_coverage_<n>` and `bias`,
#' whose values are unchanged by any monotonic transform) always appear only
#' under their natural-scale name regardless of `append`.
#'
#' For the full configuration schema, see the JSON Schema files installed
#' with the package under
#' `system.file("schema", package = "hubPredEvalsData")`.
#'
#' @export
generate_eval_data <- function(
  hub_path,
  config_path,
  out_path,
  oracle_output = NULL,
  hub_con = NULL
) {
  config <- read_predevals_config(hub_path, config_path)
  if (is.null(hub_con)) {
    hub_con <- hubData::connect_hub(hub_path)
  }
  if (is.null(oracle_output)) {
    oracle_output <- hubData::connect_target_oracle_output(hub_path) |>
      dplyr::collect()
  }
  # Oracle output may carry an `as_of` provenance column from versioned
  # target-data. It holds a single value per observational unit (no version
  # axis to resolve), but hubEvals scoring rejects columns outside the task-id
  # keys plus `oracle_value`, so drop it before scoring. A no-op when absent.
  oracle_output$as_of <- NULL
  for (target in config$targets) {
    generate_target_eval_data(
      hub_path,
      config,
      out_path,
      oracle_output,
      target,
      hub_con
    )
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
  target,
  hub_con
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

  # Subset the oracle to this target once. It arrives holding every target's
  # rows, but the scoring join only ever matches this target's, so the others
  # are dead weight on every (eval_set x by) join. See #82.
  oracle_output <- filter_to_target(oracle_output, task_groups_w_target)

  # Per-forecast scores don't depend on the eval set or the disaggregation, so
  # each forecast is scored once and its scores are then summarized for every
  # eval set and `by` it appears in. See #80 and #83.
  eval_set_forecasts <- purrr::map(eval_sets, function(eval_set) {
    load_model_out_in_eval_set(
      hub_path,
      target_id,
      eval_set,
      config$rounds_idx,
      hub_con = hub_con
    ) |>
      get_forecast_keys()
  })
  row_scores <- score_forecasts_once(
    hub_con = hub_con,
    forecast_keys = eval_set_forecasts,
    oracle_output = oracle_output,
    metric_name_to_output_type = metric_name_to_output_type,
    transform = transform,
    task_groups_w_target = task_groups_w_target
  )

  for (i in seq_along(eval_sets)) {
    eval_set <- eval_sets[[i]]
    forecasts <- eval_set_forecasts[[i]]
    if (nrow(forecasts) == 0) {
      cli::cli_inform(
        "No model output data found for target {.val {target_id}}
         in evaluation set {.val {eval_set$eval_set_name}}."
      )
      next
    }

    set_row_scores <- get_row_scores_in_eval_set(row_scores, forecasts)
    model_out_tbl <- NULL
    if (is.null(set_row_scores)) {
      # Some output type has forecasts in this eval set but nothing to score
      # (for example, no oracle values yet). Score the eval set directly, as
      # before, so this case behaves exactly as it did.
      model_out_tbl <- load_model_out_in_eval_set(
        hub_path,
        target_id,
        eval_set,
        config$rounds_idx,
        hub_con = hub_con
      )
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
        task_groups_w_target = task_groups_w_target,
        row_scores = set_row_scores
      )
    }
  }
}


#' The forecasts in a model output table: its distinct rows without the
#' `output_type_id` and `value` columns, i.e. one row per model, task and
#' output type.
#' @noRd
get_forecast_keys <- function(model_out_tbl) {
  model_out_tbl |>
    dplyr::select(!dplyr::any_of(c("output_type_id", "value"))) |>
    dplyr::distinct()
}


#' Score every forecast that is in at least one eval set, once
#'
#' Model output is loaded and scored one model at a time, which keeps memory
#' use to roughly one model's forecasts. Per-forecast scores don't depend on
#' which other forecasts are scored alongside them, so this gives the same
#' scores as scoring each eval set as a whole.
#'
#' @param forecast_keys A list of forecast key tables (see
#'   `get_forecast_keys()`), one per eval set.
#' @return A named list with one element per output type: the per-forecast
#'   scores from `score_model_out(summarize = FALSE)`, sorted by forecast, or
#'   `NULL` if there was nothing to score.
#' @noRd
score_forecasts_once <- function(
  hub_con,
  forecast_keys,
  oracle_output,
  metric_name_to_output_type,
  transform,
  task_groups_w_target
) {
  output_types <- unique(metric_name_to_output_type$output_type)
  all_keys <- dplyr::bind_rows(forecast_keys) |> dplyr::distinct()
  row_scores <- purrr::set_names(
    vector("list", length(output_types)),
    output_types
  )
  if (nrow(all_keys) == 0) {
    return(row_scores)
  }

  target_con <- filter_to_target(hub_con, task_groups_w_target)
  for (model in sort(unique(all_keys$model_id))) {
    model_keys <- all_keys[all_keys$model_id == model, , drop = FALSE]
    model_out_tbl <- target_con |>
      dplyr::filter(.data[["model_id"]] == !!model) |>
      dplyr::collect() |>
      dplyr::semi_join(model_keys, by = names(model_keys))

    for (output_type in output_types) {
      type_rows <- model_out_tbl[
        model_out_tbl$output_type == output_type,
        ,
        drop = FALSE
      ]
      if (nrow(type_rows) == 0) {
        next
      }
      # relative skill and `by` only apply when summarizing
      score_args <- get_score_args(
        output_type = output_type,
        metric_name_to_output_type = metric_name_to_output_type,
        relative_metrics = NULL,
        baseline = NULL,
        by = NULL,
        transform = transform,
        task_groups_w_target = task_groups_w_target
      )
      score_args$model_out_tbl <- type_rows
      score_args$oracle_output <- oracle_output
      score_args$summarize <- FALSE
      scores <- score_or_skip_unobserved(score_args)
      if (!is.null(scores)) {
        row_scores[[output_type]] <- c(row_scores[[output_type]], list(scores))
      }
    }
  }

  purrr::map(row_scores, bind_row_scores)
}


#' Score one model's forecasts, returning `NULL` if none can be scored
#'
#' scoringutils errors when no forecast has every value it needs, typically
#' because none have an oracle value yet. Scored together with other models,
#' those forecasts would just be dropped, so here the model is skipped.
#' @noRd
score_or_skip_unobserved <- function(score_args) {
  tryCatch(
    do.call(score_model_out, score_args),
    error = function(e) {
      if (grepl("no forecasts\\s+are\\s+left", conditionMessage(e))) {
        return(NULL)
      }
      stop(e)
    }
  )
}


#' Combine per-model scores into one table, sorted by forecast
#'
#' Sorting makes the order of the scores, and so the order in which they are
#' summed when summarizing, the same on every run.
#' @noRd
bind_row_scores <- function(score_list) {
  if (length(score_list) == 0) {
    return(NULL)
  }
  metrics <- attr(score_list[[1]], "metrics")
  scores <- dplyr::bind_rows(score_list)
  sort_cols <- setdiff(names(scores), metrics)
  scores <- dplyr::arrange(scores, dplyr::across(dplyr::all_of(sort_cols)))
  copy_score_attrs(scores, score_list[[1]])
}


#' Copy the attributes `score_model_out()` sets on per-forecast scores
#'
#' `summarize_model_out_scores()` needs them, and `bind_rows()` and
#' `semi_join()` don't always keep them.
#' @noRd
copy_score_attrs <- function(to, from) {
  for (name in c("metrics", "transform_append")) {
    attr(to, name) <- attr(from, name)
  }
  to
}


#' The per-forecast scores for the forecasts in one eval set
#'
#' @return A named list like `row_scores`, restricted to the eval set, or
#'   `NULL` if some output type has forecasts in the eval set but no scores.
#' @noRd
get_row_scores_in_eval_set <- function(row_scores, forecasts) {
  set_scores <- list()
  for (output_type in names(row_scores)) {
    type_forecasts <- forecasts[
      forecasts$output_type == output_type,
      ,
      drop = FALSE
    ]
    scores <- row_scores[[output_type]]
    if (nrow(type_forecasts) == 0 || is.null(scores)) {
      return(NULL)
    }
    key_cols <- intersect(
      setdiff(names(type_forecasts), "output_type"),
      names(scores)
    )
    in_set <- dplyr::semi_join(scores, type_forecasts, by = key_cols)
    if (nrow(in_set) == 0) {
      return(NULL)
    }
    set_scores[[output_type]] <- copy_score_attrs(in_set, scores)
  }
  set_scores
}


#' Get and save scores for a target in a given evaluation set,
#' collecting across different output types as necessary.
#' Scores are saved in .csv files in subdirectorys under out_path with one of
#' two structures:
#' - If by is NULL, the scores are saved in
#' out_path/target_id/eval_set_name/scores.csv
#' - If by is not NULL, the scores are saved in
#' out_path/target_id/eval_set_name/by/scores.csv
#'
#' If `row_scores` is given (per-forecast scores for the eval set, by output
#' type; see `score_forecasts_once()`), those are summarized and
#' `model_out_tbl` is not used. Otherwise `model_out_tbl` is scored.
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
  task_groups_w_target,
  row_scores = NULL
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
      task_groups_w_target = task_groups_w_target,
      row_scores = row_scores[[.x]]
    )
  ) |>
    # Union the (model_id, by) keys across output types with a full join: a
    # model (or cell) scored only on a later output type must survive rather
    # than be dropped by anchoring on the first type's frame. NA fills where a
    # model did not submit a given type, the same as the reverse direction
    # (anchor-present model lacking a later type) already produced. See #75.
    purrr::reduce(dplyr::full_join, by = c("model_id", by))

  scores <- collapse_output_type_n(
    scores,
    unique(metric_name_to_output_type$output_type)
  )

  group_cols <- c("model_id", by)

  # The row order coming out of scoring reflects arrow's parallel, scan-order
  # collect in load_model_out_in_eval_set(), so two runs on identical data emit
  # the same rows shuffled. Sort on the (model_id, by) key, which is unique per
  # row, so scores.csv is byte-stable across runs and diffable. See #25.
  scores <- dplyr::arrange(scores, dplyr::across(dplyr::all_of(group_cols)))

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


#' Collapse the per-output-type scored counts into a single `n` column.
#'
#' Each output type contributes its scored-forecast count as an `n_<output_type>`
#' column (from `score_model_out(include_count = TRUE)`), sitting just after that
#' type's metric columns.
#'
#' The counts collapse to a single `n` unless some row holds two counts that
#' differ. Agreement is judged row by row, over non-NA values only (per-row max
#' against per-row min). So a row where only one output type contributed a count
#' keeps that lone value. An NA count means the model submitted nothing for that
#' output type, which the row's NA metric columns already show.
#'
#' If any row does hold two differing counts, the output types genuinely diverge
#' for this target and the per-output-type columns are left as-is. See #19.
#'
#' @param scores The merged wide-format scores, one row per `(model_id, by)`.
#' @param output_types The output types scored for this target, used to locate
#'   the `n_<output_type>` columns.
#' @return `scores` with the count columns collapsed to a single `n`, or
#'   unchanged when the counts diverge.
#' @noRd
collapse_output_type_n <- function(scores, output_types) {
  n_cols <- intersect(paste0("n_", output_types), names(scores))
  row_max <- do.call(pmax, c(scores[n_cols], na.rm = TRUE))
  row_min <- do.call(pmin, c(scores[n_cols], na.rm = TRUE))
  if (all(row_max == row_min, na.rm = TRUE)) {
    scores[n_cols] <- NULL
    scores[["n"]] <- row_max
  }
  scores
}


#' Get scores for a target in a given evaluation set for a specific output type.
#'
#' If `transform` is set and the output type is transformable
#' (see `get_transformable_output_types()`), scores are computed with the
#' scale transformation applied. The hubEvals long-format output (with a
#' `scale` column when `append = TRUE`) is pivoted to wide format here so that
#' transformed-scale metrics become label-prefixed columns alongside their
#' natural-scale counterparts.
#'
#' If `row_scores` (per-forecast scores for this output type) is given, they
#' are summarized with `summarize_model_out_scores()`, which gives the same
#' result as scoring `model_out_tbl` with the same arguments.
#'
#' `score_model_out()` is imported, not called as `hubEvals::`, so tests can mock it.
#' @importFrom hubEvals score_model_out summarize_model_out_scores
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
  task_groups_w_target,
  row_scores = NULL
) {
  score_args <- get_score_args(
    output_type = output_type,
    metric_name_to_output_type = metric_name_to_output_type,
    relative_metrics = relative_metrics,
    baseline = baseline,
    by = by,
    transform = transform,
    task_groups_w_target = task_groups_w_target
  )
  metrics <- score_args$metrics
  relative_metrics <- score_args$relative_metrics
  score_by <- score_args$by
  apply_transform <- !is.null(score_args$transform)
  transform_append <- isTRUE(score_args$transform_append)
  transform_label <- score_args$transform_label

  if (is.null(row_scores)) {
    score_args$model_out_tbl <- model_out_tbl |>
      dplyr::filter(.data[["output_type"]] == !!output_type)
    score_args$oracle_output <- oracle_output
    scores <- do.call(score_model_out, score_args)
  } else {
    scores <- summarize_model_out_scores(
      row_scores,
      relative_metrics = relative_metrics,
      baseline = baseline,
      by = score_by,
      include_count = score_args$include_count
    )
  }

  # Set the scored-forecast count aside as `n_<output_type>` before the metric
  # columns are reshaped below, then re-attach it as the final column so it ends
  # up immediately after this output type's metrics once the per-output-type
  # frames are merged. Under `transform_append = TRUE` scoring emits one row per
  # scale with identical counts, so a distinct on the group + count collapses
  # them to one row per group. See #19.
  count_col <- paste0("n_", output_type)
  group_cols <- c("model_id", by)
  counts <- dplyr::distinct(scores[c(group_cols, "count")])
  names(counts)[names(counts) == "count"] <- count_col
  scores[["count"]] <- NULL

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
    # Reorder so each metric's natural and transformed columns sit together,
    # matching the `metrics` order in `predevals-options.json`.
    ordered_metric_cols <- expand_relative_skill_metrics(
      metrics = metrics,
      relative_metrics = relative_metrics
    ) |>
      expand_transformed_metrics(
        transformable_metrics = metrics,
        label = transform_label,
        append = transform_append
      )
    scores <- scores[c("model_id", by, ordered_metric_cols)]
  }

  dplyr::left_join(scores, counts, by = group_cols)
}


#' Arguments to `score_model_out()` for one output type, other than
#' `model_out_tbl` and `oracle_output`
#'
#' Used both to score an eval set and to score forecasts once before
#' summarizing, so the two are scored the same way.
#' @noRd
get_score_args <- function(
  output_type,
  metric_name_to_output_type,
  relative_metrics,
  baseline,
  by,
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
    metrics = metrics,
    relative_metrics = relative_metrics,
    baseline = baseline,
    by = score_by,
    # Count the forecasts actually scored per group (after the oracle join drops
    # units with no observation), rather than counting submitted predictions.
    # hubEvals returns this as a `count` column; we carry it as `n_<output_type>`
    # in get_scores_for_output_type() and merge it back in get_and_save_scores().
    # See #19.
    include_count = TRUE
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
  score_args
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

  unscaled_rel_skill_cols <- paste0(relative_metrics, "_relative_skill")
  scores <- dplyr::select(scores, !dplyr::all_of(unscaled_rel_skill_cols))

  ordered_metric_cols <- expand_relative_skill_metrics(
    metrics = metrics,
    relative_metrics = relative_metrics
  )

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
#' Transform-invariant metrics (`interval_coverage_<n>`, `bias`) are
#' reported on a single, un-suffixed scale: under `append = TRUE` the
#' transformed-scale duplicate is dropped before the join; under
#' `append = FALSE` the metric column keeps its natural-scale name since the
#' transformed value equals the natural value (see #63 and
#' `is_transform_invariant()`).
#'
#' The double-underscore separator lets downstream tools split a column name
#' into (base-metric, transform-label) unambiguously, since no current metric
#' name contains `"__"`.
#' @noRd
pivot_transformed_scores <- function(scores, by, label, append) {
  id_cols <- c("model_id", by)
  if (!append) {
    return(suffix_transformed_metric_cols(scores, id_cols, label))
  }

  is_natural <- scores$scale == "natural"
  keep_cols <- setdiff(names(scores), "scale")
  natural <- scores[is_natural, keep_cols, drop = FALSE]
  transformed <- scores[!is_natural, keep_cols, drop = FALSE]
  transformed <- transformed[,
    !is_transform_invariant(names(transformed)),
    drop = FALSE
  ]
  transformed <- suffix_transformed_metric_cols(transformed, id_cols, label)
  dplyr::left_join(natural, transformed, by = id_cols)
}


#' Rename non-id columns in `df` by suffixing them with `"__<label>"`. Columns
#' for transform-invariant metrics (`interval_coverage_<n>`, `bias`) are left
#' un-suffixed: their transformed value equals the natural value, so the
#' natural-scale name is the honest label. See #63.
#' @noRd
suffix_transformed_metric_cols <- function(df, id_cols, label) {
  is_transformed_metric <- !names(df) %in% id_cols &
    !is_transform_invariant(names(df))
  names(df)[is_transformed_metric] <- paste0(
    names(df)[is_transformed_metric],
    "__",
    label
  )
  df
}
