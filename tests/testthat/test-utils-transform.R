test_that(".transform_functions names match the latest schema's fun enum", {
  schema_path <- system.file(
    "schema",
    get_latest_schema_version(),
    "config_schema.json",
    package = "hubPredEvalsData"
  )
  schema <- jsonlite::read_json(schema_path)
  enum <- unlist(schema$`$defs`$transform_config$properties$fun$enum)
  expect_setequal(names(.transform_functions), enum)
})

test_that("get_transform_function returns the allowlisted function for each name", {
  for (name in names(.transform_functions)) {
    expect_identical(
      get_transform_function(name),
      .transform_functions[[name]]
    )
  }
})

test_that("get_transform_function errors on an unknown name", {
  expect_error(
    get_transform_function("not_a_function"),
    regexp = 'Unknown transform function "not_a_function"'
  )
})
