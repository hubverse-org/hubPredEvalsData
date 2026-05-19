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

test_that("resolve_target_transform returns NULL when target opts out", {
  target <- list(transform = FALSE)
  defaults <- list(fun = "log_shift")
  expect_null(resolve_target_transform(target, defaults))
})

test_that("resolve_target_transform returns the per-target transform when set", {
  target <- list(transform = list(fun = "sqrt", label = "sqrt"))
  defaults <- list(fun = "log_shift")
  expect_equal(
    resolve_target_transform(target, defaults),
    list(fun = "sqrt", label = "sqrt")
  )
})

test_that("resolve_target_transform inherits transform_defaults when target has none", {
  target <- list()
  defaults <- list(fun = "log_shift", args = list(offset = 1))
  expect_equal(
    resolve_target_transform(target, defaults),
    defaults
  )
})

test_that("resolve_target_transform returns NULL when neither is set", {
  expect_null(resolve_target_transform(list(), NULL))
})

test_that("resolve_target_transform: per-target wins entirely; no merge with defaults", {
  target <- list(transform = list(fun = "sqrt"))
  defaults <- list(fun = "log_shift", args = list(offset = 1), label = "log")
  # The defaults' args/label do not bleed into the per-target transform.
  expect_equal(
    resolve_target_transform(target, defaults),
    list(fun = "sqrt")
  )
})

test_that("get_transform_label uses configured label when present", {
  expect_equal(
    get_transform_label(list(fun = "log_shift", label = "log")),
    "log"
  )
})

test_that("get_transform_label falls back to function name", {
  expect_equal(
    get_transform_label(list(fun = "sqrt")),
    "sqrt"
  )
})
