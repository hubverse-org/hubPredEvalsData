#' Build a temporary fixture hub with two transformable targets, derived from
#' the ecfh hub by duplicating `base_target`'s rows under `new_target`.
#'
#' Writes hub files into `hub_path` (which must be a fresh, empty directory,
#' typically `withr::local_tempdir()`). The duplication covers `tasks.json`,
#' each `model-output/*.csv`, and `target-data/oracle-output.csv`, so callers
#' can load the extended oracle from the hub via
#' `hubData::connect_target_oracle_output()`.
#'
#' Used by tests that need two transformable targets to exercise per-target
#' transform isolation. The ecfh fixture only ships with one such target
#' (`wk inc flu hosp`), so the second is created by data duplication.
setup_two_target_hub <- function(
  hub_path,
  base_target = "wk inc flu hosp",
  new_target = "wk inc flu death"
) {
  src <- testthat::test_path("testdata", "ecfh")
  file.copy(
    list.files(src, full.names = TRUE),
    hub_path,
    recursive = TRUE
  )

  # Add new_target as an allowed value for the `target` task_id and append
  # a target_metadata entry mirroring base_target's, in every task group
  # that contains base_target.
  tasks_path <- file.path(hub_path, "hub-config", "tasks.json")
  tasks <- jsonlite::read_json(tasks_path, simplifyVector = FALSE)
  task_groups <- tasks$rounds[[1]]$model_tasks
  for (i in seq_along(task_groups)) {
    metas <- task_groups[[i]]$target_metadata
    base_idx <- which(vapply(
      metas,
      function(m) identical(m$target_id, base_target),
      logical(1)
    ))
    if (length(base_idx) == 0) {
      next
    }

    task_groups[[i]]$task_ids$target$optional <- c(
      task_groups[[i]]$task_ids$target$optional,
      new_target
    )
    new_md <- metas[[base_idx]]
    new_md$target_id <- new_target
    new_md$target_keys$target <- new_target
    task_groups[[i]]$target_metadata <- c(metas, list(new_md))
  }
  tasks$rounds[[1]]$model_tasks <- task_groups
  jsonlite::write_json(
    tasks,
    tasks_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  # Duplicate model-output rows under the new target name.
  model_out_files <- list.files(
    file.path(hub_path, "model-output"),
    pattern = "\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  for (f in model_out_files) {
    rows <- read.csv(f, check.names = FALSE)
    base_rows <- rows[rows$target == base_target, ]
    if (nrow(base_rows) > 0) {
      base_rows$target <- new_target
      utils::write.csv(rbind(rows, base_rows), f, row.names = FALSE)
    }
  }

  # Extend the oracle output similarly, writing the result back to disk so
  # callers can load it via hubData::connect_target_oracle_output().
  oracle_path <- file.path(hub_path, "target-data", "oracle-output.csv")
  oracle <- read.csv(oracle_path)
  base_oracle <- oracle[oracle$target == base_target, ]
  base_oracle$target <- new_target
  utils::write.csv(rbind(oracle, base_oracle), oracle_path, row.names = FALSE)

  invisible(hub_path)
}
