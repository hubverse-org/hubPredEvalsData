#' Build a tiny ordinal-pmf hub for #48 regression testing.
#'
#' Writes a minimal hub into `hub_path` (a fresh empty dir, typically
#' `withr::local_tempdir()`): always `hub-config/` (tasks.json, admin.json),
#' plus the oracle and model-output CSVs when `incl_data = TRUE`.
#'
#' Data design: the hub has one ordinal pmf target across 4 bins and one
#' forecast task per location, each with a single observed outcome. The
#' observed bins are hand-picked (and distinct) so the good-model / bad-model
#' forecasts can be built relative to them: good-model concentrates
#' probability mass near the observed bin, bad-model concentrates it at the
#' opposite end. That coupling is what lets the test assert
#' rps(good-model) < rps(bad-model) deterministically.
#'
#' Forecast probabilities are powers of 1/2 so each 4-bin forecast sums to
#' exactly 1.0 in IEEE 754, sidestepping the scoringRules
#' `<= .Machine$double.eps` tolerance gate (hubEvals#74) that blocks scoring
#' rps on the ecfh fixture.
#'
#' @param hub_path Fresh empty directory to write the hub into.
#' @param schema_version hubverse tasks-schema version for the hub's
#'   tasks.json. Only `"v6.0.0"` (default; pmf `output_type_id` is a single
#'   `required` array) and `"v3.0.0"` (pmf `output_type_id` is split across
#'   `required` / `optional`) are supported, so tests can exercise both sides
#'   of the v4 schema boundary.
#' @param include_optional `"v3.0.0"` only: when `TRUE`, the last pmf level is
#'   placed in `output_type_id$optional` instead of `$required`, to exercise
#'   the non-empty-`$optional` error path in `validate_ordinal_pmf_dispatch()`.
#' @param incl_data When `TRUE` (default), also write the oracle and
#'   model-output CSVs. Config-validation tests only read `tasks.json`, so
#'   they pass `FALSE` to skip the unused data files.
setup_ordinal_pmf_hub <- function(
  hub_path,
  schema_version = c("v6.0.0", "v3.0.0"),
  include_optional = FALSE,
  incl_data = TRUE
) {
  schema_version <- match.arg(schema_version)

  bins <- c("low", "moderate", "high", "very high")
  locations <- c("A", "B", "C")
  observed <- c(A = "low", B = "moderate", C = "high")
  good_forecasts <- list(
    A = c(0.5, 0.25, 0.125, 0.125),
    B = c(0.25, 0.5, 0.125, 0.125),
    C = c(0.125, 0.125, 0.5, 0.25)
  )
  bad_forecasts <- list(
    A = c(0.125, 0.125, 0.25, 0.5),
    B = c(0.125, 0.125, 0.5, 0.25),
    C = c(0.5, 0.25, 0.125, 0.125)
  )

  # pmf output_type_id wrapper shape differs across the v4 schema boundary:
  # v4+ is a single `required` array; v2/v3 splits values across
  # `required` / `optional`. `include_optional` exercises the v3 split.
  pmf_output_type_id <- if (schema_version == "v6.0.0") {
    list(required = as.list(bins))
  } else if (include_optional) {
    list(
      required = as.list(bins[-length(bins)]),
      optional = list(bins[[length(bins)]])
    )
  } else {
    list(required = as.list(bins), optional = NULL)
  }

  dir.create(file.path(hub_path, "hub-config"), recursive = TRUE)
  if (incl_data) {
    dir.create(file.path(hub_path, "target-data"), recursive = TRUE)
    dir.create(
      file.path(hub_path, "model-output", "good-model"),
      recursive = TRUE
    )
    dir.create(
      file.path(hub_path, "model-output", "bad-model"),
      recursive = TRUE
    )
  }

  tasks <- list(
    schema_version = paste0(
      "https://raw.githubusercontent.com/hubverse-org/schemas/main/",
      schema_version,
      "/tasks-schema.json"
    ),
    rounds = list(list(
      round_id_from_variable = TRUE,
      round_id = "reference_date",
      model_tasks = list(list(
        task_ids = list(
          reference_date = list(
            required = NULL,
            optional = list("2024-01-01")
          ),
          target = list(required = NULL, optional = list("hosp rate category")),
          horizon = list(required = NULL, optional = list(0L)),
          location = list(required = NULL, optional = as.list(locations)),
          target_end_date = list(
            required = NULL,
            optional = list("2024-01-01")
          )
        ),
        output_type = list(
          pmf = list(
            output_type_id = pmf_output_type_id,
            value = list(type = "double", minimum = 0, maximum = 1)
          )
        ),
        target_metadata = list(list(
          target_id = "hosp rate category",
          target_name = "hospitalization rate category",
          target_units = "rate per 100,000 population",
          target_keys = list(target = "hosp rate category"),
          target_type = "ordinal",
          description = "Synthetic ordinal pmf target for #48 regression test.",
          is_step_ahead = TRUE,
          time_unit = "week"
        ))
      )),
      submissions_due = list(start = "2024-01-01", end = "2024-01-01")
    ))
  )
  # output_type_id_datatype is a v4+ tasks-schema field; omit it for v3.
  if (schema_version == "v6.0.0") {
    tasks$output_type_id_datatype <- "character"
  }
  jsonlite::write_json(
    tasks,
    file.path(hub_path, "hub-config", "tasks.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  jsonlite::write_json(
    list(
      schema_version = paste0(
        "https://raw.githubusercontent.com/hubverse-org/schemas/",
        "main/v3.0.0/admin-schema.json"
      ),
      name = "Synthetic ordinal pmf hub",
      maintainer = "test",
      contact = list(name = "test", email = "test@example.com"),
      repository_url = "https://example.com",
      file_format = list("csv"),
      timezone = "UTC",
      model_output_dir = "model-output",
      hub_models = list(),
      flags = list()
    ),
    file.path(hub_path, "hub-config", "admin.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  if (incl_data) {
    oracle <- purrr::map(locations, function(loc) {
      data.frame(
        location = loc,
        target_end_date = "2024-01-01",
        target = "hosp rate category",
        output_type = "pmf",
        output_type_id = bins,
        oracle_value = as.integer(bins == observed[[loc]]),
        stringsAsFactors = FALSE
      )
    }) |>
      purrr::list_rbind()
    utils::write.csv(
      oracle,
      file.path(hub_path, "target-data", "oracle-output.csv"),
      row.names = FALSE
    )

    write_model_output <- function(model_id, forecasts) {
      rows <- purrr::map(locations, function(loc) {
        data.frame(
          reference_date = "2024-01-01",
          location = loc,
          horizon = 0L,
          target = "hosp rate category",
          target_end_date = "2024-01-01",
          output_type = "pmf",
          output_type_id = bins,
          value = forecasts[[loc]],
          stringsAsFactors = FALSE
        )
      }) |>
        purrr::list_rbind()
      utils::write.csv(
        rows,
        file.path(
          hub_path,
          "model-output",
          model_id,
          paste0("2024-01-01-", model_id, ".csv")
        ),
        row.names = FALSE
      )
    }
    write_model_output("good-model", good_forecasts)
    write_model_output("bad-model", bad_forecasts)
  }

  invisible(hub_path)
}


#' Write a predevals config for the synthetic ordinal-pmf hub.
#'
#' Companion to `setup_ordinal_pmf_hub()`: targets the `"hosp rate category"`
#' target that helper creates.
#'
#' @param hub_path Hub directory; the config is written to
#'   `predevals-config.yaml` inside it.
#' @param metrics Character vector of metrics to request for the target.
#' @return Path to the written config file.
write_ordinal_pmf_config <- function(
  hub_path,
  metrics = c("log_score", "rps")
) {
  config_path <- file.path(hub_path, "predevals-config.yaml")
  yaml::write_yaml(
    list(
      schema_version = paste0(
        "https://raw.githubusercontent.com/hubverse-org/",
        "hubPredEvalsData/main/inst/schema/v1.1.0/config_schema.json"
      ),
      rounds_idx = 0L,
      targets = list(list(
        target_id = "hosp rate category",
        metrics = as.list(metrics)
      )),
      eval_sets = list(list(
        eval_set_name = "Full",
        round_filters = list(min = "2024-01-01")
      ))
    ),
    config_path
  )
  config_path
}
