library(rlang)

hub_path <- testthat::test_path("testdata", "ecfh")
model_out_tbl <- hubData::connect_hub(hub_path) |>
  dplyr::collect()
oracle_output <- read.csv(
  testthat::test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
)
oracle_output[["target_end_date"]] <- as.Date(oracle_output[[
  "target_end_date"
]])

make_score_fixtures_one_set <- function(set_name, model_out_tbl) {
  for (by in list(
    NULL,
    "location",
    "reference_date",
    "horizon",
    "target_end_date"
  )) {
    # compute scores using hubEvals
    expected_mean_scores <- hubEvals::score_model_out(
      model_out_tbl = model_out_tbl |>
        dplyr::filter(.data[["output_type"]] == "mean"),
      oracle_output = oracle_output,
      metrics = "se_point",
      relative_metrics = "se_point",
      baseline = "FS-base",
      by = c("model_id", by)
    )
    expected_mean_scores <- as.data.frame(expected_mean_scores)[
      c("model_id", by, "se_point_scaled_relative_skill", "se_point")
    ]
    expected_median_scores <- hubEvals::score_model_out(
      model_out_tbl = model_out_tbl |>
        dplyr::filter(.data[["output_type"]] == "median"),
      oracle_output = oracle_output,
      metrics = "ae_point",
      relative_metrics = "ae_point",
      baseline = "FS-base",
      by = c("model_id", by)
    )
    expected_median_scores <- as.data.frame(expected_median_scores)[
      c("model_id", by, "ae_point_scaled_relative_skill", "ae_point")
    ]
    expected_quantile_scores <- hubEvals::score_model_out(
      model_out_tbl = model_out_tbl |>
        dplyr::filter(.data[["output_type"]] == "quantile"),
      oracle_output = oracle_output,
      metrics = c(
        "wis",
        "ae_median",
        "interval_coverage_50",
        "interval_coverage_95"
      ),
      relative_metrics = c("wis", "ae_median"),
      baseline = "FS-base",
      by = c("model_id", by),
      include_count = TRUE
    )
    # The scored count is per output type and oracle-aware (forecasts with no
    # observation are not counted). On the complete ecfh oracle every output
    # type is scored on the same units, so the counts agree and collapse to a
    # single `n`; take it from the quantile scores. See #19.
    scored_counts <- as.data.frame(expected_quantile_scores)[
      c("model_id", by, "count")
    ]
    names(scored_counts)[names(scored_counts) == "count"] <- "n"
    expected_quantile_scores <- as.data.frame(expected_quantile_scores)[
      c(
        "model_id",
        by,
        "wis_scaled_relative_skill",
        "wis",
        "ae_median_scaled_relative_skill",
        "ae_median",
        "interval_coverage_50",
        "interval_coverage_95"
      )
    ]
    expected_scores <- expected_mean_scores |>
      dplyr::left_join(expected_median_scores, by = c("model_id", by)) |>
      dplyr::left_join(expected_quantile_scores, by = c("model_id", by)) |>
      dplyr::left_join(scored_counts, by = c("model_id", by))

    save_path <- testthat::test_path("testdata", "expected-scores")
    if (!dir.exists(save_path)) {
      dir.create(save_path, recursive = TRUE)
    }

    file_name <- paste0(
      "scores_",
      set_name,
      ifelse(is.null(by), "", paste0("_by_", by)),
      ".csv"
    )
    file_name <- gsub(" ", "_", file_name)
    write.csv(
      expected_scores,
      file = file.path(save_path, file_name),
      row.names = FALSE
    )
  }
}

make_score_fixtures_one_set(
  "Full season",
  model_out_tbl
)
make_score_fixtures_one_set(
  "Last 5 weeks",
  model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17")
)
make_score_fixtures_one_set(
  "Alabama, positive horizons",
  model_out_tbl |> dplyr::filter(location == "01", horizon %in% c(1L, 2L, 3L))
)
