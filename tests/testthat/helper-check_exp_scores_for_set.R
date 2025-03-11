#' Helper function to check that the output files were created and have the expected contents
#' for one evaluation set
#' @param out_path The path to the output directory where scores were saved.
#' @param set_name The name of the evaluation set
#' @param model_out_tbl The model output table, filtered to data for the evaluation window.
#' @param oracle_output The oracle output.
#' @param include_rel Whether to include relative metrics in the expected scores.
check_exp_scores_for_set <- function(out_path, set_name, model_out_tbl, oracle_output,
                                     include_rel = FALSE) {
  # check that the output files were created and have the expected contents
  # disaggregated by `by` if non-NULL, otherwise no disaggregation
  for (by in list(NULL, "location", "reference_date", "horizon", "target_end_date")) {
    if (is.null(by)) {
      scores_path <- file.path(out_path, "wk inc flu hosp", set_name, "scores.csv")
    } else {
      scores_path <- file.path(out_path, "wk inc flu hosp", set_name, by, "scores.csv")
    }
    testthat::expect_true(file.exists(scores_path))

    actual_scores <- read.csv(scores_path)

    file_name <- paste0("scores_", set_name, ifelse(is.null(by), "", paste0("_by_", by)), ".csv")
    file_name <- gsub(" ", "_", file_name)
    expected_scores_path <- testthat::test_path(
      "testdata", "expected-scores",
      file_name
    )
    expected_scores <- read.csv(expected_scores_path)
    if (!include_rel) {
      expected_scores <- expected_scores |>
        dplyr::select(-dplyr::contains("relative"))
    }

    expect_df_equal_up_to_order(actual_scores, expected_scores, ignore_attr = TRUE) # nolint: object_usage_linter
  }
}
