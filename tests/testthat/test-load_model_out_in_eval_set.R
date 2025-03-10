test_that(
  "load_model_out_in_eval_set succeeds, all rounds",
  {
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path = test_path("testdata", "ecfh"),
      target_id = "wk flu hosp rate category",
      eval_set = list(
        eval_set_name = "all"
      )
    )

    expected_model_out_tbl <- hubData::connect_hub(
      test_path("testdata", "ecfh")
    ) |>
      dplyr::filter(
        target == "wk flu hosp rate category"
      ) |>
      dplyr::collect()

    expect_df_equal_up_to_order(
      model_out_tbl,
      expected_model_out_tbl
    )
  }
)


test_that(
  "load_model_out_in_eval_set succeeds, min only",
  {
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path = test_path("testdata", "ecfh"),
      target_id = "wk flu hosp rate category",
      eval_set = list(
        eval_set_name = "some subset",
        round_filters = list(
          min = "2022-11-19"
        )
      )
    )

    expected_model_out_tbl <- hubData::connect_hub(
      test_path("testdata", "ecfh")
    ) |>
      dplyr::filter(
        target == "wk flu hosp rate category",
        reference_date >= "2022-11-19"
      ) |>
      dplyr::collect()

    expect_df_equal_up_to_order(
      model_out_tbl,
      expected_model_out_tbl
    )
  }
)


test_that(
  "load_model_out_in_eval_set succeeds, n_last only",
  {
    # n_last = 5: we expect 2022-12-17, 2022-12-24, 2022-12-31, 2023-01-07, 2023-01-14
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path = test_path("testdata", "ecfh"),
      target_id = "wk flu hosp rate category",
      eval_set = list(
        eval_set_name = "some subset",
        round_filters = list(
          n_last = 5
        )
      )
    )

    expected_model_out_tbl <- hubData::connect_hub(
      test_path("testdata", "ecfh")
    ) |>
      dplyr::filter(
        target == "wk flu hosp rate category",
        reference_date >= "2022-12-17"
      ) |>
      dplyr::collect()

    expect_df_equal_up_to_order(
      model_out_tbl,
      expected_model_out_tbl
    )
    expect_setequal(
      unique(model_out_tbl$reference_date),
      c("2022-12-17", "2023-01-14")
    )

    # n_last = 4: we expect 2022-12-24, 2022-12-31, 2023-01-07, 2023-01-14
    # (but note that ecfh has only 2023-01-14 from this set)
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path = test_path("testdata", "ecfh"),
      target_id = "wk flu hosp rate category",
      eval_set = list(
        eval_set_name = "some subset",
        round_filters = list(
          n_last = 4
        )
      )
    )

    expected_model_out_tbl <- hubData::connect_hub(
      test_path("testdata", "ecfh")
    ) |>
      dplyr::filter(
        target == "wk flu hosp rate category",
        reference_date >= "2023-01-14"
      ) |>
      dplyr::collect()

    expect_df_equal_up_to_order(
      model_out_tbl,
      expected_model_out_tbl
    )
    expect_setequal(
      unique(model_out_tbl$reference_date),
      c("2023-01-14")
    )
  }
)


test_that(
  "load_model_out_in_eval_set succeeds, min & n_last, min superceeds",
  {
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path = test_path("testdata", "ecfh"),
      target_id = "wk flu hosp rate category",
      eval_set = list(
        eval_set_name = "some subset",
        round_filters = list(
          min = "2023-01-14",
          n_last = 9
        )
      )
    )

    expected_model_out_tbl <- hubData::connect_hub(
      test_path("testdata", "ecfh")
    ) |>
      dplyr::filter(
        target == "wk flu hosp rate category",
        reference_date >= "2023-01-14"
      ) |>
      dplyr::collect()

    expect_df_equal_up_to_order(
      model_out_tbl,
      expected_model_out_tbl
    )
    expect_setequal(
      unique(model_out_tbl$reference_date),
      c("2023-01-14")
    )
  }
)


test_that(
  "load_model_out_in_eval_set succeeds, min & n_last, n_last superceeds",
  {
    model_out_tbl <- load_model_out_in_eval_set(
      hub_path = test_path("testdata", "ecfh"),
      target_id = "wk flu hosp rate category",
      eval_set = list(
        eval_set_name = "some subset",
        round_filters = list(
          min = "2022-11-19", # there are 9 rounds on or after this date
          n_last = 5
        )
      )
    )

    expected_model_out_tbl <- hubData::connect_hub(
      test_path("testdata", "ecfh")
    ) |>
      dplyr::filter(
        target == "wk flu hosp rate category",
        reference_date >= "2022-12-17"
      ) |>
      dplyr::collect()

    expect_df_equal_up_to_order(
      model_out_tbl,
      expected_model_out_tbl
    )
    expect_setequal(
      unique(model_out_tbl$reference_date),
      c("2022-12-17", "2023-01-14")
    )
  }
)
