test_that("get_latest_schema_version returns a v-prefixed semver string", {
  result <- get_latest_schema_version()
  expect_match(result, "^v[0-9]+\\.[0-9]+\\.[0-9]+$")
})

test_that("get_latest_schema_version corresponds to a real bundled schema", {
  schema_path <- system.file(
    "schema",
    get_latest_schema_version(),
    "config_schema.json",
    package = "hubPredEvalsData"
  )
  expect_true(file.exists(schema_path))
})
