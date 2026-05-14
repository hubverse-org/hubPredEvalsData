test_that("get_model_tasks succeeds, both rounds_idx = 0 and 1", {
  hub_path <- test_path("testdata", "ecfh")
  hub_tasks_config <- hubUtils::read_config(hub_path, config = "tasks")
  model_task_0 <- get_model_tasks(hub_tasks_config, rounds_idx = 0)
  expect_length(model_task_0, 3L)

  model_task_1 <- get_model_tasks(hub_tasks_config, rounds_idx = 1)
  expect_length(model_task_1, 1L)
})


test_that("filter_task_groups_to_target works", {
  task_groups <- list(
    list(
      group_number = 1,
      target_metadata = list(
        list(target_id = "target_id_1"),
        list(target_id = "target_id_2")
      )
    ),
    list(
      group_number = 2,
      target_metadata = list(
        list(target_id = "target_id_3"),
        list(target_id = "target_id_4"),
        list(target_id = "target_id_5")
      )
    ),
    list(
      group_number = 3,
      target_metadata = list(
        list(target_id = "target_id_4")
      )
    )
  )

  expect_equal(
    filter_task_groups_to_target(task_groups, "target_id_1"),
    list(
      list(
        group_number = 1,
        target_metadata = list(
          list(target_id = "target_id_1")
        )
      )
    )
  )

  expect_equal(
    filter_task_groups_to_target(task_groups, "target_id_4"),
    list(
      list(
        group_number = 2,
        target_metadata = list(
          list(target_id = "target_id_4")
        )
      ),
      list(
        group_number = 3,
        target_metadata = list(
          list(target_id = "target_id_4")
        )
      )
    )
  )

  expect_equal(
    filter_task_groups_to_target(task_groups, "NOT A REAL TARGET ID"),
    list()
  )
})


test_that("get_task_id_values works", {
  task_groups <- list(
    list(
      task_ids = list(
        horizon = list(required = NULL, optional = 1:4),
        target = list(
          required = "target_1",
          optional = c("target_2", "target_3")
        )
      )
    ),
    list(
      task_ids = list(
        horizon = list(required = NULL, optional = 1:4),
        target = list(
          required = "target_3",
          optional = c("target_4", "target_5")
        )
      )
    )
  )

  expect_equal(
    get_task_id_values(task_groups, "horizon"),
    1:4
  )
  expect_equal(
    get_task_id_values(task_groups, "target"),
    c("target_1", "target_2", "target_3", "target_4", "target_5")
  )
})


test_that("get_output_types works", {
  task_groups <- list(
    list(
      output_type = list(
        "output_type_1" = "output_type_1_value",
        "output_type_2" = "output_type_2_value"
      )
    ),
    list(
      output_type = list(
        "output_type_2" = "output_type_2_value",
        "output_type_3" = "output_type_3_value"
      )
    ),
    list(
      output_type = list(
        "output_type_3" = "output_type_3_value"
      )
    )
  )

  expect_equal(
    get_output_types(task_groups),
    c("output_type_1", "output_type_2", "output_type_3")
  )
})


test_that("is_target_ordinal works", {
  task_groups_w_target <- list(
    list(
      target_metadata = list(
        list(target_type = "ordinal")
      )
    )
  )

  expect_true(is_target_ordinal(task_groups_w_target))

  task_groups_w_target <- list(
    list(
      target_metadata = list(
        list(target_type = "nominal")
      )
    )
  )

  expect_false(is_target_ordinal(task_groups_w_target))
})


#' Build a task_groups list with the v4+ output_type_id wrapper shape
#' (`{required: [...]}`) that `get_output_type_ids_for_type()` reads. Each
#' `...` arg is a named list `output_type = c(values)` per group.
make_task_groups <- function(...) {
  lapply(list(...), function(group) {
    list(
      output_type = lapply(group, function(values) {
        list(output_type_id = list(required = values))
      })
    )
  })
}


test_that("get_output_type_ids_for_type works", {
  task_groups <- make_task_groups(
    list(
      quantile = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
      pmf = c("low", "medium", "high")
    ),
    list(
      quantile = c(0.1, 0.5, 0.9),
      pmf = c("low", "medium", "high")
    )
  )
  expect_equal(
    get_output_type_ids_for_type(task_groups, "quantile"),
    c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
  )
  expect_equal(
    get_output_type_ids_for_type(task_groups, "pmf"),
    c("low", "medium", "high")
  )

  # incompatible values: expect an error
  task_groups <- make_task_groups(
    list(
      quantile = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8),
      pmf = c("low", "medium", "high")
    ),
    list(quantile = c(0.1, 0.5, 0.9), pmf = c("low", "medium", "high"))
  )
  expect_error(
    get_output_type_ids_for_type(task_groups, "quantile"),
    "have different values across task groups."
  )

  # incompatible value order: expect an error
  task_groups <- make_task_groups(
    list(
      quantile = c(0.9, 0.1, 0.5),
      pmf = c("low", "medium", "high")
    ),
    list(quantile = c(0.1, 0.5, 0.9), pmf = c("low", "medium", "high"))
  )
  expect_error(
    get_output_type_ids_for_type(task_groups, "quantile"),
    "have different order across task groups."
  )
})
