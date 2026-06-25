get_target <- function(opts, target_id) {
  Filter(function(t) t$target_id == target_id, opts$targets)[[1]]
}


# Compare against a checked-in expected predevals-options.json fixture. The
# function output is round-tripped through jsonlite with the same `auto_unbox`
# the docker pipeline uses, so the comparison is against the actual serialised
# artifact rather than the in-memory R structure.
expect_matches_options_fixture <- function(config_name, fixture_name) {
  opts <- generate_predevals_options(
    hub_path = testthat::test_path("testdata", "ecfh"),
    config_path = testthat::test_path(
      "testdata",
      "test_configs",
      config_name
    )
  )
  actual <- jsonlite::fromJSON(
    jsonlite::toJSON(opts, auto_unbox = TRUE),
    simplifyVector = FALSE
  )
  expected <- jsonlite::read_json(
    testthat::test_path("testdata", "expected-predevals-options", fixture_name)
  )
  testthat::expect_equal(actual, expected)
}


test_that("output matches the expected predevals-options.json (no transforms)", {
  expect_matches_options_fixture(
    "config_valid_rel_metrics.yaml",
    "rel_metrics.json"
  )
})


test_that("output matches the expected predevals-options.json (per-target transform)", {
  expect_matches_options_fixture(
    "config_valid_transform_per_target.yaml",
    "transform_per_target.json"
  )
})


test_that("output matches the expected predevals-options.json (inherited transform_defaults)", {
  expect_matches_options_fixture(
    "config_valid_transform_defaults.yaml",
    "transform_defaults.json"
  )
})


test_that("output matches the expected predevals-options.json (relative metrics, append: false)", {
  expect_matches_options_fixture(
    "config_valid_transform_no_append_rel.yaml",
    "transform_no_append_rel.json"
  )
})


test_that("target_name and target_units are pulled from the hub target_metadata", {
  opts <- generate_predevals_options(
    hub_path = test_path("testdata", "ecfh"),
    config_path = test_path(
      "testdata",
      "test_configs",
      "config_valid_rel_metrics.yaml"
    )
  )

  hosp <- get_target(opts, "wk inc flu hosp")
  expect_identical(hosp$target_name, "incident influenza hospitalizations")
  expect_identical(hosp$target_units, "count")

  category <- get_target(opts, "wk flu hosp rate category")
  expect_identical(
    category$target_name,
    "week ahead weekly influenza hospitalization rate category"
  )
  expect_identical(category$target_units, "rate per 100,000 population")

  # spliced in just after target_id, where the dashboard expects them
  expect_identical(
    names(hosp)[1:3],
    c("target_id", "target_name", "target_units")
  )
})


test_that("a pmf-only target with inherited defaults warns and gets no transform", {
  hub_path <- test_path("testdata", "ecfh")
  config_path <- test_path(
    "testdata",
    "test_configs",
    "config_warn_transform_pmf_inherited.yaml"
  )

  expect_warning(
    opts <- generate_predevals_options(hub_path, config_path),
    "cannot apply to target"
  )

  # pmf is non-transformable, so the inherited transform is reported as no
  # transform, consistent with it being skipped at scoring time.
  category <- get_target(opts, "wk flu hosp rate category")
  expect_null(category$transform)

  # The transformable target still inherits the default transform.
  hosp <- get_target(opts, "wk inc flu hosp")
  expect_identical(hosp$transform$fun, "log_shift")
})
