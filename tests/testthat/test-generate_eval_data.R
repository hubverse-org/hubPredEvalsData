test_that(
  "generate_eval_data works, integration test, no relative metrics",
  {
    out_path <- withr::local_tempdir()
    hub_path <- test_path("testdata", "ecfh")
    model_out_tbl <- hubData::connect_hub(hub_path) |>
      dplyr::collect()
    oracle_output <- read.csv(
      test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
    )
    oracle_output[["target_end_date"]] <- as.Date(oracle_output[["target_end_date"]])

    generate_eval_data(
      hub_path = hub_path,
      config_path = test_path("testdata", "test_configs", "config_valid_mean_median_quantile.yaml"),
      out_path = out_path,
      oracle_output = oracle_output
    )

    check_exp_scores_for_set(out_path,
                             "Full season",
                             model_out_tbl,
                             oracle_output)
    check_exp_scores_for_set(out_path,
                             "Last 5 weeks",
                             model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
                             oracle_output)
    check_exp_scores_for_set(out_path,
                             "Alabama, positive horizons",
                             model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
                             oracle_output)
  }
)

test_that(
  "generate_eval_data works, integration test, with relative metrics",
  {
    out_path <- withr::local_tempdir()
    hub_path <- test_path("testdata", "ecfh")
    model_out_tbl <- hubData::connect_hub(hub_path) |>
      dplyr::collect()
    oracle_output <- read.csv(
      test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
    )
    oracle_output[["target_end_date"]] <- as.Date(oracle_output[["target_end_date"]])

    generate_eval_data(
      hub_path = hub_path,
      config_path = test_path("testdata", "test_configs", "config_valid_mean_median_quantile_rel.yaml"),
      out_path = out_path,
      oracle_output = oracle_output
    )

    check_exp_scores_for_set(out_path,
                             "Full season",
                             model_out_tbl,
                             oracle_output,
                             include_rel = TRUE)
    check_exp_scores_for_set(out_path,
                             "Last 5 weeks",
                             model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
                             oracle_output,
                             include_rel = TRUE)
    check_exp_scores_for_set(out_path,
                             "Alabama, positive horizons",
                             model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
                             oracle_output,
                             include_rel = TRUE)
  }
)

test_that(
  "generate_eval_data generates an informative message and partial results if an evaluation set has no data",
  {
    out_path <- withr::local_tempdir()
    hub_path <- test_path("testdata", "ecfh")
    model_out_tbl <- hubData::connect_hub(hub_path) |>
      dplyr::collect()
    oracle_output <- read.csv(
      test_path("testdata", "ecfh", "target-data", "oracle-output.csv")
    )
    oracle_output[["target_end_date"]] <- as.Date(oracle_output[["target_end_date"]])

    expect_message(
      generate_eval_data(
        hub_path = hub_path,
        config_path = test_path("testdata", "test_configs", "config_valid_set_filters_no_data.yaml"),
        out_path = out_path,
        oracle_output = oracle_output
      ),
      'No model output data found for target "wk inc flu hosp" in evaluation set "Valid locations with no data in test'
    )

    check_exp_scores_for_set(out_path,
                             "Full season",
                             model_out_tbl,
                             oracle_output,
                             include_rel = FALSE)
    check_exp_scores_for_set(out_path,
                             "Last 5 weeks",
                             model_out_tbl |> dplyr::filter(reference_date >= "2022-12-17"),
                             oracle_output,
                             include_rel = FALSE)
  }
)
