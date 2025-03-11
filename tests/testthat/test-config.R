test_that(
  "read_predevals_config succeeds, valid yaml file",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config succeeds, valid yaml file with task id filters",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid_set_filters.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config succeeds, valid yaml file with length 1 arrays",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid_length_one_arrays.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config succeeds, valid yaml file with relative metrics",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid_rel_metrics.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config succeeds, valid yaml file with no min_round_id",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid_no_min_round_id.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config succeeds, valid yaml file with no disaggregate_by",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid_no_disaggregate_by.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config succeeds, valid yaml file with no task_id_text",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_snapshot(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid_no_task_id_text.yaml")
      )
    )
  }
)

test_that(
  "read_predevals_config fails, invalid yaml file",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_yaml.yaml")
      ),
      regexp = "Error reading predevals config file"
    )
  }
)

test_that(
  "read_predevals_config fails, no schema_version in yaml file",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_no_schema_version.yaml")
      ),
      regexp = "The predevals config file is required to contain a `schema_version` property."
    )
  }
)

test_that(
  "read_predevals_config fails, schema_version is array in yaml file",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_array_schema_version.yaml")
      ),
      regexp = "The `schema_version` property of the config schema must be a string."
    )
  }
)

test_that(
  "read_predevals_config fails, arbitrary string schema_version in yaml file",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_malformed_schema_version.yaml")
      ),
      regexp = "Invalid `schema_version` property of the config schema."
    )
  }
)

test_that(
  "read_predevals_config fails, well-formatted but unsupported schema_version in yaml file",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_nonexist_schema_version.yaml")
      ),
      regexp = "Invalid predevals schema version."
    )
  }
)

test_that(
  "read_predevals_config fails, multiple modeling round groups",
  {
    hub_path <- test_path("testdata", "test_hub_invalid_mult_rnd")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid.yaml")
      ),
      regexp = "hubPredEvalsData only supports hubs with a single round group specified in `tasks.json`."
    )
  }
)

test_that(
  "read_predevals_config fails, round_id_from_variable false",
  {
    hub_path <- test_path("testdata", "test_hub_invalid_rifv_F")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_valid.yaml")
      ),
      regexp = "hubPredEvalsData only supports hubs with `round_id_from_variable` set to `true` in `tasks.json`."
    )
  }
)

test_that(
  "read_predevals_config fails, invalid target id",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_targets_target_id.yaml")
      ),
      regexp = 'Target id "THIS IS NOT A REAL TARGET ID" not found in any task group.'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid metrics",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_targets_metrics.yaml")
      ),
      regexp = 'Unsupported metrics: "THIS IS NOT A SUPPORTED METRIC" and "coverage_95".'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid disaggregate by",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_targets_disaggregate_by.yaml")
      ),
      regexp = 'Disaggregate by variables "THIS IS NOT A TASK ID VARIABLE" and "NEITHER IS THIS"'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid eval set n_last",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_set_n_last.yaml")
      ),
      regexp = "/eval_sets/1/round_filters/n_last must be >= 1"
    )
  }
)

test_that(
  "read_predevals_config fails, invalid eval set min_round_id",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_set_min_round_id.yaml")
      ),
      regexp = 'Minimum round id "THIS IS NOT A ROUND ID" for evaluation set is not a valid round id for the hub.'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid eval set task filter variable name",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_set_filter_task_name.yaml")
      ),
      regexp = 'Specified task filters based on task id variable "not_a_real_task_id" that is not found in the hub'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid eval set task filter variable value",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_set_filter_task_value.yaml")
      ),
      regexp = 'Evaluation set specified invalid filter values on task id variable "location": "not a real location"'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid task_id_text, not a task id variable",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_task_id_text_non_task_id.yaml")
      ),
      regexp = 'Specified `task_id_text` for task id variable "NOT_A_REAL_TASK_ID"'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid task_id_text, missing entries",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_task_id_text_missing.yaml")
      ),
      regexp = 'For task id variable "location", missing the following values: "US" and "25"'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid relative metrics, not a subset of metrics",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_rel_metrics_non_metric.yaml")
      ),
      regexp = 'Relative metric not found in the requested metrics: "log_score".'
    )
  }
)

test_that(
  "read_predevals_config fails, invalid relative metrics, no baseline",
  {
    hub_path <- test_path("testdata", "ecfh")
    expect_error(
      read_config(
        hub_path,
        test_path("testdata", "test_configs",
                  "config_invalid_rel_metrics_no_baseline.yaml")
      ),
      regexp = "must have property baseline when property relative_metrics is present"
    )
  }
)
