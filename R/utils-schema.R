#' Latest bundled schema version.
#'
#' Highest version directory under `inst/schema/`, compared via
#' [package_version()] for correct semver ordering (e.g. `v1.10.0` >
#' `v1.2.0`).
#'
#' @return Version string with `v` prefix, e.g. `"v1.1.0"`.
#' @noRd
get_latest_schema_version <- function() {
  schema_root <- system.file("schema", package = "hubPredEvalsData")
  versions <- list.files(schema_root, pattern = "^v[0-9]")
  parsed <- package_version(sub("^v", "", versions))
  versions[parsed == max(parsed)]
}
