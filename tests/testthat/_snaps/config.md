# read_predevals_config succeeds, valid yaml file

    Code
      read_config(hub_path, test_path("testdata", "test_configs", "config_valid.yaml"))
    Output
      $schema_version
      [1] "https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.0/config_schema.json"
      
      $targets
      $targets[[1]]
      $targets[[1]]$target_id
      [1] "wk inc flu hosp"
      
      $targets[[1]]$metrics
      [1] "wis"                  "ae_median"            "interval_coverage_50"
      [4] "interval_coverage_95"
      
      $targets[[1]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      $targets[[2]]
      $targets[[2]]$target_id
      [1] "wk flu hosp rate category"
      
      $targets[[2]]$metrics
      [1] "log_score" "rps"      
      
      $targets[[2]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      
      $eval_sets
      $eval_sets[[1]]
      $eval_sets[[1]]$eval_set_name
      [1] "Full season"
      
      $eval_sets[[1]]$round_filters
      $eval_sets[[1]]$round_filters$min
      [1] "2023-01-21"
      
      
      
      $eval_sets[[2]]
      $eval_sets[[2]]$eval_set_name
      [1] "Last 4 weeks"
      
      $eval_sets[[2]]$round_filters
      $eval_sets[[2]]$round_filters$min
      [1] "2023-01-21"
      
      $eval_sets[[2]]$round_filters$n_last
      [1] 4
      
      
      
      
      $task_id_text
      $task_id_text$location
      $task_id_text$location$US
      [1] "United States"
      
      $task_id_text$location$`01`
      [1] "Alabama"
      
      $task_id_text$location$`02`
      [1] "Alaska"
      
      $task_id_text$location$`04`
      [1] "Arizona"
      
      $task_id_text$location$`05`
      [1] "Arkansas"
      
      $task_id_text$location$`06`
      [1] "California"
      
      $task_id_text$location$`08`
      [1] "Colorado"
      
      $task_id_text$location$`09`
      [1] "Connecticut"
      
      $task_id_text$location$`10`
      [1] "Delaware"
      
      $task_id_text$location$`11`
      [1] "District of Columbia"
      
      $task_id_text$location$`12`
      [1] "Florida"
      
      $task_id_text$location$`13`
      [1] "Georgia"
      
      $task_id_text$location$`15`
      [1] "Hawaii"
      
      $task_id_text$location$`16`
      [1] "Idaho"
      
      $task_id_text$location$`17`
      [1] "Illinois"
      
      $task_id_text$location$`18`
      [1] "Indiana"
      
      $task_id_text$location$`19`
      [1] "Iowa"
      
      $task_id_text$location$`20`
      [1] "Kansas"
      
      $task_id_text$location$`21`
      [1] "Kentucky"
      
      $task_id_text$location$`22`
      [1] "Louisiana"
      
      $task_id_text$location$`23`
      [1] "Maine"
      
      $task_id_text$location$`24`
      [1] "Maryland"
      
      $task_id_text$location$`25`
      [1] "Massachusetts"
      
      $task_id_text$location$`26`
      [1] "Michigan"
      
      $task_id_text$location$`27`
      [1] "Minnesota"
      
      $task_id_text$location$`28`
      [1] "Mississippi"
      
      $task_id_text$location$`29`
      [1] "Missouri"
      
      $task_id_text$location$`30`
      [1] "Montana"
      
      $task_id_text$location$`31`
      [1] "Nebraska"
      
      $task_id_text$location$`32`
      [1] "Nevada"
      
      $task_id_text$location$`33`
      [1] "New Hampshire"
      
      $task_id_text$location$`34`
      [1] "New Jersey"
      
      $task_id_text$location$`35`
      [1] "New Mexico"
      
      $task_id_text$location$`36`
      [1] "New York"
      
      $task_id_text$location$`37`
      [1] "North Carolina"
      
      $task_id_text$location$`38`
      [1] "North Dakota"
      
      $task_id_text$location$`39`
      [1] "Ohio"
      
      $task_id_text$location$`40`
      [1] "Oklahoma"
      
      $task_id_text$location$`41`
      [1] "Oregon"
      
      $task_id_text$location$`42`
      [1] "Pennsylvania"
      
      $task_id_text$location$`44`
      [1] "Rhode Island"
      
      $task_id_text$location$`45`
      [1] "South Carolina"
      
      $task_id_text$location$`46`
      [1] "South Dakota"
      
      $task_id_text$location$`47`
      [1] "Tennessee"
      
      $task_id_text$location$`48`
      [1] "Texas"
      
      $task_id_text$location$`49`
      [1] "Utah"
      
      $task_id_text$location$`50`
      [1] "Vermont"
      
      $task_id_text$location$`51`
      [1] "Virginia"
      
      $task_id_text$location$`53`
      [1] "Washington"
      
      $task_id_text$location$`54`
      [1] "West Virginia"
      
      $task_id_text$location$`55`
      [1] "Wisconsin"
      
      $task_id_text$location$`56`
      [1] "Wyoming"
      
      $task_id_text$location$`60`
      [1] "American Samoa"
      
      $task_id_text$location$`66`
      [1] "Guam"
      
      $task_id_text$location$`69`
      [1] "Northern Mariana Islands"
      
      $task_id_text$location$`72`
      [1] "Puerto Rico"
      
      $task_id_text$location$`74`
      [1] "U.S. Minor Outlying Islands"
      
      $task_id_text$location$`78`
      [1] "Virgin Islands"
      
      
      

# read_predevals_config succeeds, valid yaml file with length 1 arrays

    Code
      read_config(hub_path, test_path("testdata", "test_configs",
        "config_valid_length_one_arrays.yaml"))
    Output
      $schema_version
      [1] "https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.0/config_schema.json"
      
      $targets
      $targets[[1]]
      $targets[[1]]$target_id
      [1] "wk inc flu hosp"
      
      $targets[[1]]$metrics
      [1] "wis"
      
      $targets[[1]]$disaggregate_by
      [1] "location"
      
      
      
      $eval_sets
      $eval_sets[[1]]
      $eval_sets[[1]]$eval_set_name
      [1] "Full season"
      
      $eval_sets[[1]]$round_filters
      $eval_sets[[1]]$round_filters$min
      [1] "2023-01-21"
      
      
      
      

# read_predevals_config succeeds, valid yaml file with relative metrics

    Code
      read_config(hub_path, test_path("testdata", "test_configs",
        "config_valid_rel_metrics.yaml"))
    Output
      $schema_version
      [1] "https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.0/config_schema.json"
      
      $targets
      $targets[[1]]
      $targets[[1]]$target_id
      [1] "wk inc flu hosp"
      
      $targets[[1]]$metrics
      [1] "wis"                  "ae_median"            "interval_coverage_50"
      [4] "interval_coverage_95"
      
      $targets[[1]]$relative_metrics
      [1] "wis"       "ae_median"
      
      $targets[[1]]$baseline
      [1] "FS-base"
      
      $targets[[1]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      $targets[[2]]
      $targets[[2]]$target_id
      [1] "wk flu hosp rate category"
      
      $targets[[2]]$metrics
      [1] "log_score" "rps"      
      
      $targets[[2]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      
      $eval_sets
      $eval_sets[[1]]
      $eval_sets[[1]]$eval_set_name
      [1] "Full season"
      
      $eval_sets[[1]]$round_filters
      $eval_sets[[1]]$round_filters$min
      [1] "2023-01-21"
      
      
      
      $eval_sets[[2]]
      $eval_sets[[2]]$eval_set_name
      [1] "Last 4 weeks"
      
      $eval_sets[[2]]$round_filters
      $eval_sets[[2]]$round_filters$min
      [1] "2023-01-21"
      
      $eval_sets[[2]]$round_filters$n_last
      [1] 4
      
      
      
      
      $task_id_text
      $task_id_text$location
      $task_id_text$location$US
      [1] "United States"
      
      $task_id_text$location$`01`
      [1] "Alabama"
      
      $task_id_text$location$`02`
      [1] "Alaska"
      
      $task_id_text$location$`04`
      [1] "Arizona"
      
      $task_id_text$location$`05`
      [1] "Arkansas"
      
      $task_id_text$location$`06`
      [1] "California"
      
      $task_id_text$location$`08`
      [1] "Colorado"
      
      $task_id_text$location$`09`
      [1] "Connecticut"
      
      $task_id_text$location$`10`
      [1] "Delaware"
      
      $task_id_text$location$`11`
      [1] "District of Columbia"
      
      $task_id_text$location$`12`
      [1] "Florida"
      
      $task_id_text$location$`13`
      [1] "Georgia"
      
      $task_id_text$location$`15`
      [1] "Hawaii"
      
      $task_id_text$location$`16`
      [1] "Idaho"
      
      $task_id_text$location$`17`
      [1] "Illinois"
      
      $task_id_text$location$`18`
      [1] "Indiana"
      
      $task_id_text$location$`19`
      [1] "Iowa"
      
      $task_id_text$location$`20`
      [1] "Kansas"
      
      $task_id_text$location$`21`
      [1] "Kentucky"
      
      $task_id_text$location$`22`
      [1] "Louisiana"
      
      $task_id_text$location$`23`
      [1] "Maine"
      
      $task_id_text$location$`24`
      [1] "Maryland"
      
      $task_id_text$location$`25`
      [1] "Massachusetts"
      
      $task_id_text$location$`26`
      [1] "Michigan"
      
      $task_id_text$location$`27`
      [1] "Minnesota"
      
      $task_id_text$location$`28`
      [1] "Mississippi"
      
      $task_id_text$location$`29`
      [1] "Missouri"
      
      $task_id_text$location$`30`
      [1] "Montana"
      
      $task_id_text$location$`31`
      [1] "Nebraska"
      
      $task_id_text$location$`32`
      [1] "Nevada"
      
      $task_id_text$location$`33`
      [1] "New Hampshire"
      
      $task_id_text$location$`34`
      [1] "New Jersey"
      
      $task_id_text$location$`35`
      [1] "New Mexico"
      
      $task_id_text$location$`36`
      [1] "New York"
      
      $task_id_text$location$`37`
      [1] "North Carolina"
      
      $task_id_text$location$`38`
      [1] "North Dakota"
      
      $task_id_text$location$`39`
      [1] "Ohio"
      
      $task_id_text$location$`40`
      [1] "Oklahoma"
      
      $task_id_text$location$`41`
      [1] "Oregon"
      
      $task_id_text$location$`42`
      [1] "Pennsylvania"
      
      $task_id_text$location$`44`
      [1] "Rhode Island"
      
      $task_id_text$location$`45`
      [1] "South Carolina"
      
      $task_id_text$location$`46`
      [1] "South Dakota"
      
      $task_id_text$location$`47`
      [1] "Tennessee"
      
      $task_id_text$location$`48`
      [1] "Texas"
      
      $task_id_text$location$`49`
      [1] "Utah"
      
      $task_id_text$location$`50`
      [1] "Vermont"
      
      $task_id_text$location$`51`
      [1] "Virginia"
      
      $task_id_text$location$`53`
      [1] "Washington"
      
      $task_id_text$location$`54`
      [1] "West Virginia"
      
      $task_id_text$location$`55`
      [1] "Wisconsin"
      
      $task_id_text$location$`56`
      [1] "Wyoming"
      
      $task_id_text$location$`60`
      [1] "American Samoa"
      
      $task_id_text$location$`66`
      [1] "Guam"
      
      $task_id_text$location$`69`
      [1] "Northern Mariana Islands"
      
      $task_id_text$location$`72`
      [1] "Puerto Rico"
      
      $task_id_text$location$`74`
      [1] "U.S. Minor Outlying Islands"
      
      $task_id_text$location$`78`
      [1] "Virgin Islands"
      
      
      

# read_predevals_config succeeds, valid yaml file with no min_round_id

    Code
      read_config(hub_path, test_path("testdata", "test_configs",
        "config_valid_no_min_round_id.yaml"))
    Output
      $schema_version
      [1] "https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.0/config_schema.json"
      
      $targets
      $targets[[1]]
      $targets[[1]]$target_id
      [1] "wk inc flu hosp"
      
      $targets[[1]]$metrics
      [1] "wis"                  "ae_median"            "interval_coverage_50"
      [4] "interval_coverage_95"
      
      $targets[[1]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      $targets[[2]]
      $targets[[2]]$target_id
      [1] "wk flu hosp rate category"
      
      $targets[[2]]$metrics
      [1] "log_score" "rps"      
      
      $targets[[2]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      
      $eval_sets
      $eval_sets[[1]]
      $eval_sets[[1]]$eval_set_name
      [1] "Full season"
      
      
      
      $task_id_text
      $task_id_text$location
      $task_id_text$location$US
      [1] "United States"
      
      $task_id_text$location$`01`
      [1] "Alabama"
      
      $task_id_text$location$`02`
      [1] "Alaska"
      
      $task_id_text$location$`04`
      [1] "Arizona"
      
      $task_id_text$location$`05`
      [1] "Arkansas"
      
      $task_id_text$location$`06`
      [1] "California"
      
      $task_id_text$location$`08`
      [1] "Colorado"
      
      $task_id_text$location$`09`
      [1] "Connecticut"
      
      $task_id_text$location$`10`
      [1] "Delaware"
      
      $task_id_text$location$`11`
      [1] "District of Columbia"
      
      $task_id_text$location$`12`
      [1] "Florida"
      
      $task_id_text$location$`13`
      [1] "Georgia"
      
      $task_id_text$location$`15`
      [1] "Hawaii"
      
      $task_id_text$location$`16`
      [1] "Idaho"
      
      $task_id_text$location$`17`
      [1] "Illinois"
      
      $task_id_text$location$`18`
      [1] "Indiana"
      
      $task_id_text$location$`19`
      [1] "Iowa"
      
      $task_id_text$location$`20`
      [1] "Kansas"
      
      $task_id_text$location$`21`
      [1] "Kentucky"
      
      $task_id_text$location$`22`
      [1] "Louisiana"
      
      $task_id_text$location$`23`
      [1] "Maine"
      
      $task_id_text$location$`24`
      [1] "Maryland"
      
      $task_id_text$location$`25`
      [1] "Massachusetts"
      
      $task_id_text$location$`26`
      [1] "Michigan"
      
      $task_id_text$location$`27`
      [1] "Minnesota"
      
      $task_id_text$location$`28`
      [1] "Mississippi"
      
      $task_id_text$location$`29`
      [1] "Missouri"
      
      $task_id_text$location$`30`
      [1] "Montana"
      
      $task_id_text$location$`31`
      [1] "Nebraska"
      
      $task_id_text$location$`32`
      [1] "Nevada"
      
      $task_id_text$location$`33`
      [1] "New Hampshire"
      
      $task_id_text$location$`34`
      [1] "New Jersey"
      
      $task_id_text$location$`35`
      [1] "New Mexico"
      
      $task_id_text$location$`36`
      [1] "New York"
      
      $task_id_text$location$`37`
      [1] "North Carolina"
      
      $task_id_text$location$`38`
      [1] "North Dakota"
      
      $task_id_text$location$`39`
      [1] "Ohio"
      
      $task_id_text$location$`40`
      [1] "Oklahoma"
      
      $task_id_text$location$`41`
      [1] "Oregon"
      
      $task_id_text$location$`42`
      [1] "Pennsylvania"
      
      $task_id_text$location$`44`
      [1] "Rhode Island"
      
      $task_id_text$location$`45`
      [1] "South Carolina"
      
      $task_id_text$location$`46`
      [1] "South Dakota"
      
      $task_id_text$location$`47`
      [1] "Tennessee"
      
      $task_id_text$location$`48`
      [1] "Texas"
      
      $task_id_text$location$`49`
      [1] "Utah"
      
      $task_id_text$location$`50`
      [1] "Vermont"
      
      $task_id_text$location$`51`
      [1] "Virginia"
      
      $task_id_text$location$`53`
      [1] "Washington"
      
      $task_id_text$location$`54`
      [1] "West Virginia"
      
      $task_id_text$location$`55`
      [1] "Wisconsin"
      
      $task_id_text$location$`56`
      [1] "Wyoming"
      
      $task_id_text$location$`60`
      [1] "American Samoa"
      
      $task_id_text$location$`66`
      [1] "Guam"
      
      $task_id_text$location$`69`
      [1] "Northern Mariana Islands"
      
      $task_id_text$location$`72`
      [1] "Puerto Rico"
      
      $task_id_text$location$`74`
      [1] "U.S. Minor Outlying Islands"
      
      $task_id_text$location$`78`
      [1] "Virgin Islands"
      
      
      

# read_predevals_config succeeds, valid yaml file with no disaggregate_by

    Code
      read_config(hub_path, test_path("testdata", "test_configs",
        "config_valid_no_disaggregate_by.yaml"))
    Output
      $schema_version
      [1] "https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.0/config_schema.json"
      
      $targets
      $targets[[1]]
      $targets[[1]]$target_id
      [1] "wk inc flu hosp"
      
      $targets[[1]]$metrics
      [1] "wis"                  "ae_median"            "interval_coverage_50"
      [4] "interval_coverage_95"
      
      
      $targets[[2]]
      $targets[[2]]$target_id
      [1] "wk flu hosp rate category"
      
      $targets[[2]]$metrics
      [1] "log_score" "rps"      
      
      
      
      $eval_sets
      $eval_sets[[1]]
      $eval_sets[[1]]$eval_set_name
      [1] "Full season"
      
      $eval_sets[[1]]$round_filters
      $eval_sets[[1]]$round_filters$min
      [1] "2023-01-21"
      
      
      
      $eval_sets[[2]]
      $eval_sets[[2]]$eval_set_name
      [1] "Last 4 weeks"
      
      $eval_sets[[2]]$round_filters
      $eval_sets[[2]]$round_filters$min
      [1] "2023-01-21"
      
      $eval_sets[[2]]$round_filters$n_last
      [1] 4
      
      
      
      
      $task_id_text
      $task_id_text$location
      $task_id_text$location$US
      [1] "United States"
      
      $task_id_text$location$`01`
      [1] "Alabama"
      
      $task_id_text$location$`02`
      [1] "Alaska"
      
      $task_id_text$location$`04`
      [1] "Arizona"
      
      $task_id_text$location$`05`
      [1] "Arkansas"
      
      $task_id_text$location$`06`
      [1] "California"
      
      $task_id_text$location$`08`
      [1] "Colorado"
      
      $task_id_text$location$`09`
      [1] "Connecticut"
      
      $task_id_text$location$`10`
      [1] "Delaware"
      
      $task_id_text$location$`11`
      [1] "District of Columbia"
      
      $task_id_text$location$`12`
      [1] "Florida"
      
      $task_id_text$location$`13`
      [1] "Georgia"
      
      $task_id_text$location$`15`
      [1] "Hawaii"
      
      $task_id_text$location$`16`
      [1] "Idaho"
      
      $task_id_text$location$`17`
      [1] "Illinois"
      
      $task_id_text$location$`18`
      [1] "Indiana"
      
      $task_id_text$location$`19`
      [1] "Iowa"
      
      $task_id_text$location$`20`
      [1] "Kansas"
      
      $task_id_text$location$`21`
      [1] "Kentucky"
      
      $task_id_text$location$`22`
      [1] "Louisiana"
      
      $task_id_text$location$`23`
      [1] "Maine"
      
      $task_id_text$location$`24`
      [1] "Maryland"
      
      $task_id_text$location$`25`
      [1] "Massachusetts"
      
      $task_id_text$location$`26`
      [1] "Michigan"
      
      $task_id_text$location$`27`
      [1] "Minnesota"
      
      $task_id_text$location$`28`
      [1] "Mississippi"
      
      $task_id_text$location$`29`
      [1] "Missouri"
      
      $task_id_text$location$`30`
      [1] "Montana"
      
      $task_id_text$location$`31`
      [1] "Nebraska"
      
      $task_id_text$location$`32`
      [1] "Nevada"
      
      $task_id_text$location$`33`
      [1] "New Hampshire"
      
      $task_id_text$location$`34`
      [1] "New Jersey"
      
      $task_id_text$location$`35`
      [1] "New Mexico"
      
      $task_id_text$location$`36`
      [1] "New York"
      
      $task_id_text$location$`37`
      [1] "North Carolina"
      
      $task_id_text$location$`38`
      [1] "North Dakota"
      
      $task_id_text$location$`39`
      [1] "Ohio"
      
      $task_id_text$location$`40`
      [1] "Oklahoma"
      
      $task_id_text$location$`41`
      [1] "Oregon"
      
      $task_id_text$location$`42`
      [1] "Pennsylvania"
      
      $task_id_text$location$`44`
      [1] "Rhode Island"
      
      $task_id_text$location$`45`
      [1] "South Carolina"
      
      $task_id_text$location$`46`
      [1] "South Dakota"
      
      $task_id_text$location$`47`
      [1] "Tennessee"
      
      $task_id_text$location$`48`
      [1] "Texas"
      
      $task_id_text$location$`49`
      [1] "Utah"
      
      $task_id_text$location$`50`
      [1] "Vermont"
      
      $task_id_text$location$`51`
      [1] "Virginia"
      
      $task_id_text$location$`53`
      [1] "Washington"
      
      $task_id_text$location$`54`
      [1] "West Virginia"
      
      $task_id_text$location$`55`
      [1] "Wisconsin"
      
      $task_id_text$location$`56`
      [1] "Wyoming"
      
      $task_id_text$location$`60`
      [1] "American Samoa"
      
      $task_id_text$location$`66`
      [1] "Guam"
      
      $task_id_text$location$`69`
      [1] "Northern Mariana Islands"
      
      $task_id_text$location$`72`
      [1] "Puerto Rico"
      
      $task_id_text$location$`74`
      [1] "U.S. Minor Outlying Islands"
      
      $task_id_text$location$`78`
      [1] "Virgin Islands"
      
      
      

# read_predevals_config succeeds, valid yaml file with no task_id_text

    Code
      read_config(hub_path, test_path("testdata", "test_configs",
        "config_valid_no_task_id_text.yaml"))
    Output
      $schema_version
      [1] "https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.0/config_schema.json"
      
      $targets
      $targets[[1]]
      $targets[[1]]$target_id
      [1] "wk inc flu hosp"
      
      $targets[[1]]$metrics
      [1] "wis"                  "ae_median"            "interval_coverage_50"
      [4] "interval_coverage_95"
      
      $targets[[1]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      $targets[[2]]
      $targets[[2]]$target_id
      [1] "wk flu hosp rate category"
      
      $targets[[2]]$metrics
      [1] "log_score" "rps"      
      
      $targets[[2]]$disaggregate_by
      [1] "location"        "reference_date"  "horizon"         "target_end_date"
      
      
      
      $eval_sets
      $eval_sets[[1]]
      $eval_sets[[1]]$eval_set_name
      [1] "Full season"
      
      $eval_sets[[1]]$round_filters
      $eval_sets[[1]]$round_filters$min
      [1] "2023-01-21"
      
      
      
      $eval_sets[[2]]
      $eval_sets[[2]]$eval_set_name
      [1] "Last 4 weeks"
      
      $eval_sets[[2]]$round_filters
      $eval_sets[[2]]$round_filters$min
      [1] "2023-01-21"
      
      $eval_sets[[2]]$round_filters$n_last
      [1] 4
      
      
      
      

