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
#' Each entry pairs the R function (`fn`) with a human-readable `description`
#' of what it computes (sentence case, no trailing period). An entry may also
#' carry `default_args`: function defaults worth surfacing in the description
#' when the config does not set them (e.g. `log_shift` with no `offset` is a
#' plain log, so the effective `offset` is always shown). The description is
#' surfaced in the `predevals-options.json` file by
#' `get_transform_description()`; colocating it here keeps adding a transform
#' function and its description a single edit.
#'
#' Names must match the `fun` enum in
#' `inst/schema/v*/config_schema.json`. A test in
#' `test-utils-transform.R` enforces this consistency.
#' @noRd
.transform_functions <- list(
  log_shift = list(
    fn = scoringutils::log_shift,
    description = "Natural logarithm after adding an offset to the values",
    default_args = list(offset = 0)
  ),
  sqrt = list(
    fn = base::sqrt,
    description = "Square root"
  ),
  log1p = list(
    fn = base::log1p,
    description = "Natural logarithm of one plus the value"
  ),
  log = list(
    fn = base::log,
    description = "Natural logarithm"
  ),
  log10 = list(
    fn = base::log10,
    description = "Base-10 logarithm"
  ),
  log2 = list(
    fn = base::log2,
    description = "Base-2 logarithm"
  )
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
  .transform_functions[[name]]$fn
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


#' Compose a human-readable description of a transform.
#'
#' Combines the static description from `.transform_functions` with the
#' effective argument values (configured `args` layered over the entry's
#' `default_args`), yielding a single self-contained sentence for display in
#' the `predevals-options.json` file (so the dashboard does not need to know
#' anything about the transform functions).
#'
#' @param transform A transform config list (with `fun`, and optional `args`).
#' @return Character scalar, e.g.
#'   `"Natural logarithm ... (offset = 1)."`.
#' @noRd
get_transform_description <- function(transform) {
  fn_spec <- .transform_functions[[transform$fun]]
  args <- utils::modifyList(
    fn_spec$default_args %||% list(),
    transform$args %||% list()
  )
  if (length(args) == 0L) {
    return(paste0(fn_spec$description, "."))
  }
  arg_text <- paste(
    names(args),
    unlist(args),
    sep = " = ",
    collapse = ", "
  )
  paste0(fn_spec$description, " (", arg_text, ").")
}
