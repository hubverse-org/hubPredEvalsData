# Create a smaller version of the example-complex-forecast-hub to use for tests

# Starting point is running the following in the terminal:
# git clone --depth=1 https://github.com/hubverse-org/example-complex-forecast-hub tests/testthat/testdata/ecfh
# rm -rf tests/testthat/testdata/ecfh/.git
# rm -rf tests/testthat/testdata/ecfh/.github
# rm -rf tests/testthat/testdata/ecfh/LICENSE
# rm -rf tests/testthat/testdata/ecfh/README.md
# rm -rf tests/testthat/testdata/ecfh/README.Rmd
# rm -rf tests/testthat/testdata/ecfh/internal-data-raw

# Subset model output to two locations and 7 quantile levels,
# and save to new directories with shorter names to satisfy R CMD CHECK
library(dplyr)
library(hubData)

hub_path <- testthat::test_path("testdata", "ecfh")

models <- list.dirs(
  file.path(hub_path, "model-output"),
  full.names = FALSE,
  recursive = FALSE
)
reference_dates <- list.files(
  file.path(hub_path, "model-output", models[[1]]),
  full.names = FALSE,
  recursive = FALSE
) |>
  substr(1, 10)

dir.create(file.path(hub_path, "model-output", "FS-base"))
dir.create(file.path(hub_path, "model-output", "MOBS-GLEAM"))
for (model in models) {
  if (model == "Flusight-baseline") {
    model_short <- "FS-base"
  } else if (model == "MOBS-GLEAM_FLUH") {
    model_short <- "MOBS-GLEAM"
  } else {
    model_short <- model
  }
  for (reference_date in reference_dates) {
    model_out_tbl <- readr::read_csv(
      file.path(
        hub_path,
        "model-output",
        model,
        paste0(reference_date, "-", model, ".csv")
      )
    ) |>
      dplyr::filter(
        location %in% c("US", "01"),
        (output_type != "quantile") |
          (output_type_id %in% c("0.025", "0.25", "0.5", "0.75", "0.975"))
      )

    write.csv(
      model_out_tbl,
      file = file.path(
        hub_path,
        "model-output",
        model_short,
        paste0(reference_date, "-", model_short, ".csv")
      ),
      row.names = FALSE
    )
  }
}

unlink(
  file.path(hub_path, "model-output", "Flusight-baseline"),
  recursive = TRUE
)
unlink(file.path(hub_path, "model-output", "MOBS-GLEAM_FLUH"), recursive = TRUE)
