#' Output types that support scale transformation.
#'
#' Single source of truth for which output types are meaningfully
#' transformable. Adding `"sample"` here (once hubEvals sample scoring lands)
#' is the only code change sample support requires.
#'
#' @return Character vector of transformable output type names.
#' @noRd
get_transformable_output_types <- function() {
  c("quantile", "mean", "median")
}


#' Allowlist of transform functions exposed to predevals configs.
#'
#' Names must match the `fun` enum in
#' `inst/schema/v*/config_schema.json`. A test in
#' `test-utils-transform.R` enforces this consistency.
#' @noRd
.transform_functions <- list(
  log_shift = scoringutils::log_shift,
  sqrt = base::sqrt,
  log1p = base::log1p,
  log = base::log,
  log10 = base::log10,
  log2 = base::log2
)


#' Resolve a transform function name to the R function it refers to.
#'
#' Allowlist-based dispatch via `.transform_functions`.
#'
#' @param name Character scalar: one of the values allowed by the schema
#'   `transform.fun` enum.
#'
#' @return The R function corresponding to `name`.
#' @noRd
get_transform_function <- function(name) {
  if (!name %in% names(.transform_functions)) {
    cli::cli_abort("Unknown transform function {.val {name}}.")
  }
  .transform_functions[[name]]
}


#' Resolve the effective transform for a single target.
#'
#' Hierarchical, no-merge resolution:
#' 1. `target$transform == FALSE` -> opt out, return `NULL`.
#' 2. `target$transform` set      -> use it entirely (no merging with defaults).
#' 3. Otherwise                   -> inherit `transform_defaults` (or `NULL`).
#'
#' @param target One entry from `config$targets`.
#' @param transform_defaults The top-level `transform_defaults` (or `NULL`).
#'
#' @return A transform config list (with `fun` and optional `args`, `append`,
#'   `label`), or `NULL` if no transform applies to this target.
#' @importFrom rlang %||%
#' @noRd
resolve_target_transform <- function(target, transform_defaults) {
  if (isFALSE(target$transform)) {
    return(NULL)
  }
  target$transform %||% transform_defaults
}


#' Get the effective label for a transform config.
#'
#' Reflects the same fallback used downstream by `hubEvals::score_model_out()`:
#' when `label` is unset in the config, the function name stands in. Used both
#' as the `transform_label` argument to `score_model_out()` and as the
#' column-name suffix when pivoting transformed-scale scores.
#'
#' @param transform A transform config list (with at least `fun`).
#' @return Character scalar.
#' @noRd
get_transform_label <- function(transform) {
  transform$label %||% transform$fun
}
