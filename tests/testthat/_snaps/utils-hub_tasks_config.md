# get_model_tasks works with rounds_idx = 0

    Code
      get_model_tasks(hub_tasks_config, rounds_idx = 0)
    Output
      [[1]]
      [[1]]$task_ids
      [[1]]$task_ids$reference_date
      [[1]]$task_ids$reference_date$required
      NULL
      
      [[1]]$task_ids$reference_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27"
      
      
      [[1]]$task_ids$target
      [[1]]$task_ids$target$required
      NULL
      
      [[1]]$task_ids$target$optional
      [1] "wk flu hosp rate category"
      
      
      [[1]]$task_ids$horizon
      [[1]]$task_ids$horizon$required
      NULL
      
      [[1]]$task_ids$horizon$optional
      [1] 0 1 2 3
      
      
      [[1]]$task_ids$location
      [[1]]$task_ids$location$required
      NULL
      
      [[1]]$task_ids$location$optional
       [1] "US" "01" "02" "04" "05" "06" "08" "09" "10" "11" "12" "13" "15" "16" "17"
      [16] "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32"
      [31] "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "44" "45" "46" "47" "48"
      [46] "49" "50" "51" "53" "54" "55" "56" "72"
      
      
      [[1]]$task_ids$target_end_date
      [[1]]$task_ids$target_end_date$required
      NULL
      
      [[1]]$task_ids$target_end_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27" "2023-06-03" "2023-06-10" "2023-06-17"
      
      
      
      [[1]]$output_type
      [[1]]$output_type$pmf
      [[1]]$output_type$pmf$output_type_id
      [[1]]$output_type$pmf$output_type_id$required
      [1] "low"       "moderate"  "high"      "very high"
      
      [[1]]$output_type$pmf$output_type_id$optional
      NULL
      
      
      [[1]]$output_type$pmf$value
      [[1]]$output_type$pmf$value$type
      [1] "double"
      
      [[1]]$output_type$pmf$value$minimum
      [1] 0
      
      [[1]]$output_type$pmf$value$maximum
      [1] 1
      
      
      
      
      [[1]]$target_metadata
      [[1]]$target_metadata[[1]]
      [[1]]$target_metadata[[1]]$target_id
      [1] "wk flu hosp rate category"
      
      [[1]]$target_metadata[[1]]$target_name
      [1] "week ahead weekly influenza hospitalization rate category"
      
      [[1]]$target_metadata[[1]]$target_units
      [1] "rate per 100,000 population"
      
      [[1]]$target_metadata[[1]]$target_keys
      [[1]]$target_metadata[[1]]$target_keys$target
      [1] "wk flu hosp rate category"
      
      
      [[1]]$target_metadata[[1]]$target_type
      [1] "ordinal"
      
      [[1]]$target_metadata[[1]]$description
      [1] "This target represents a categorical severity level for rate of new hospitalizations per week for the week ending [horizon] weeks after the reference_date, on target_end_date."
      
      [[1]]$target_metadata[[1]]$is_step_ahead
      [1] TRUE
      
      [[1]]$target_metadata[[1]]$time_unit
      [1] "week"
      
      
      
      
      [[2]]
      [[2]]$task_ids
      [[2]]$task_ids$reference_date
      [[2]]$task_ids$reference_date$required
      NULL
      
      [[2]]$task_ids$reference_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27"
      
      
      [[2]]$task_ids$target
      [[2]]$task_ids$target$required
      NULL
      
      [[2]]$task_ids$target$optional
      [1] "wk flu hosp rate"
      
      
      [[2]]$task_ids$horizon
      [[2]]$task_ids$horizon$required
      NULL
      
      [[2]]$task_ids$horizon$optional
      [1] 0 1 2 3
      
      
      [[2]]$task_ids$location
      [[2]]$task_ids$location$required
      NULL
      
      [[2]]$task_ids$location$optional
       [1] "US" "01" "02" "04" "05" "06" "08" "09" "10" "11" "12" "13" "15" "16" "17"
      [16] "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32"
      [31] "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "44" "45" "46" "47" "48"
      [46] "49" "50" "51" "53" "54" "55" "56" "72"
      
      
      [[2]]$task_ids$target_end_date
      [[2]]$task_ids$target_end_date$required
      NULL
      
      [[2]]$task_ids$target_end_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27" "2023-06-03" "2023-06-10" "2023-06-17"
      
      
      
      [[2]]$output_type
      [[2]]$output_type$cdf
      [[2]]$output_type$cdf$output_type_id
      [[2]]$output_type$cdf$output_type_id$required
        [1]  0.25  0.50  0.75  1.00  1.25  1.50  1.75  2.00  2.25  2.50  2.75  3.00
       [13]  3.25  3.50  3.75  4.00  4.25  4.50  4.75  5.00  5.25  5.50  5.75  6.00
       [25]  6.25  6.50  6.75  7.00  7.25  7.50  7.75  8.00  8.25  8.50  8.75  9.00
       [37]  9.25  9.50  9.75 10.00 10.25 10.50 10.75 11.00 11.25 11.50 11.75 12.00
       [49] 12.25 12.50 12.75 13.00 13.25 13.50 13.75 14.00 14.25 14.50 14.75 15.00
       [61] 15.25 15.50 15.75 16.00 16.25 16.50 16.75 17.00 17.25 17.50 17.75 18.00
       [73] 18.25 18.50 18.75 19.00 19.25 19.50 19.75 20.00 20.25 20.50 20.75 21.00
       [85] 21.25 21.50 21.75 22.00 22.25 22.50 22.75 23.00 23.25 23.50 23.75 24.00
       [97] 24.25 24.50 24.75 25.00
      
      [[2]]$output_type$cdf$output_type_id$optional
      NULL
      
      
      [[2]]$output_type$cdf$value
      [[2]]$output_type$cdf$value$type
      [1] "double"
      
      [[2]]$output_type$cdf$value$minimum
      [1] 0
      
      [[2]]$output_type$cdf$value$maximum
      [1] 1
      
      
      
      
      [[2]]$target_metadata
      [[2]]$target_metadata[[1]]
      [[2]]$target_metadata[[1]]$target_id
      [1] "wk flu hosp rate"
      
      [[2]]$target_metadata[[1]]$target_name
      [1] "week ahead weekly influenza hospitalization rate"
      
      [[2]]$target_metadata[[1]]$target_units
      [1] "rate per 100,000 population"
      
      [[2]]$target_metadata[[1]]$target_keys
      [[2]]$target_metadata[[1]]$target_keys$target
      [1] "wk flu hosp rate"
      
      
      [[2]]$target_metadata[[1]]$target_type
      [1] "continuous"
      
      [[2]]$target_metadata[[1]]$description
      [1] "This target is the weekly rate of new hospitalizations per 100k population for the week ending [horizon] weeks after the reference_date, on target_end_date."
      
      [[2]]$target_metadata[[1]]$is_step_ahead
      [1] TRUE
      
      [[2]]$target_metadata[[1]]$time_unit
      [1] "week"
      
      
      
      
      [[3]]
      [[3]]$task_ids
      [[3]]$task_ids$reference_date
      [[3]]$task_ids$reference_date$required
      NULL
      
      [[3]]$task_ids$reference_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27"
      
      
      [[3]]$task_ids$target
      [[3]]$task_ids$target$required
      NULL
      
      [[3]]$task_ids$target$optional
      [1] "wk inc flu hosp"
      
      
      [[3]]$task_ids$horizon
      [[3]]$task_ids$horizon$required
      NULL
      
      [[3]]$task_ids$horizon$optional
      [1] 0 1 2 3
      
      
      [[3]]$task_ids$location
      [[3]]$task_ids$location$required
      NULL
      
      [[3]]$task_ids$location$optional
       [1] "US" "01" "02" "04" "05" "06" "08" "09" "10" "11" "12" "13" "15" "16" "17"
      [16] "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32"
      [31] "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "44" "45" "46" "47" "48"
      [46] "49" "50" "51" "53" "54" "55" "56" "72"
      
      
      [[3]]$task_ids$target_end_date
      [[3]]$task_ids$target_end_date$required
      NULL
      
      [[3]]$task_ids$target_end_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27" "2023-06-03" "2023-06-10" "2023-06-17"
      
      
      
      [[3]]$output_type
      [[3]]$output_type$mean
      [[3]]$output_type$mean$output_type_id
      [[3]]$output_type$mean$output_type_id$required
      NULL
      
      [[3]]$output_type$mean$output_type_id$optional
      [1] NA
      
      
      [[3]]$output_type$mean$value
      [[3]]$output_type$mean$value$type
      [1] "double"
      
      [[3]]$output_type$mean$value$minimum
      [1] 0
      
      
      
      [[3]]$output_type$median
      [[3]]$output_type$median$output_type_id
      [[3]]$output_type$median$output_type_id$required
      NULL
      
      [[3]]$output_type$median$output_type_id$optional
      [1] NA
      
      
      [[3]]$output_type$median$value
      [[3]]$output_type$median$value$type
      [1] "double"
      
      [[3]]$output_type$median$value$minimum
      [1] 0
      
      
      
      [[3]]$output_type$quantile
      [[3]]$output_type$quantile$output_type_id
      [[3]]$output_type$quantile$output_type_id$required
       [1] 0.010 0.025 0.050 0.100 0.150 0.200 0.250 0.300 0.350 0.400 0.450 0.500
      [13] 0.550 0.600 0.650 0.700 0.750 0.800 0.850 0.900 0.950 0.975 0.990
      
      [[3]]$output_type$quantile$output_type_id$optional
      NULL
      
      
      [[3]]$output_type$quantile$value
      [[3]]$output_type$quantile$value$type
      [1] "double"
      
      [[3]]$output_type$quantile$value$minimum
      [1] 0
      
      
      
      [[3]]$output_type$sample
      [[3]]$output_type$sample$output_type_id_params
      [[3]]$output_type$sample$output_type_id_params$is_required
      [1] TRUE
      
      [[3]]$output_type$sample$output_type_id_params$type
      [1] "integer"
      
      [[3]]$output_type$sample$output_type_id_params$min_samples_per_task
      [1] 100
      
      [[3]]$output_type$sample$output_type_id_params$max_samples_per_task
      [1] 100
      
      [[3]]$output_type$sample$output_type_id_params$compound_taskid_set
      [1] "reference_date" "location"      
      
      
      [[3]]$output_type$sample$value
      [[3]]$output_type$sample$value$type
      [1] "integer"
      
      [[3]]$output_type$sample$value$minimum
      [1] 0
      
      
      
      
      [[3]]$target_metadata
      [[3]]$target_metadata[[1]]
      [[3]]$target_metadata[[1]]$target_id
      [1] "wk inc flu hosp"
      
      [[3]]$target_metadata[[1]]$target_name
      [1] "incident influenza hospitalizations"
      
      [[3]]$target_metadata[[1]]$target_units
      [1] "count"
      
      [[3]]$target_metadata[[1]]$target_keys
      [[3]]$target_metadata[[1]]$target_keys$target
      [1] "wk inc flu hosp"
      
      
      [[3]]$target_metadata[[1]]$target_type
      [1] "continuous"
      
      [[3]]$target_metadata[[1]]$description
      [1] "This target represents the count of new hospitalizations in the week ending on the date [horizon] weeks after the reference_date, on the target_end_date."
      
      [[3]]$target_metadata[[1]]$is_step_ahead
      [1] TRUE
      
      [[3]]$target_metadata[[1]]$time_unit
      [1] "week"
      
      
      
      

# get_model_tasks works with rounds_idx = 1

    Code
      get_model_tasks(hub_tasks_config, rounds_idx = 1)
    Output
      [[1]]
      [[1]]$task_ids
      [[1]]$task_ids$reference_date
      [[1]]$task_ids$reference_date$required
      NULL
      
      [[1]]$task_ids$reference_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27"
      
      
      [[1]]$task_ids$target
      [[1]]$task_ids$target$required
      NULL
      
      [[1]]$task_ids$target$optional
      [1] "wk flu hosp rate category"
      
      
      [[1]]$task_ids$horizon
      [[1]]$task_ids$horizon$required
      NULL
      
      [[1]]$task_ids$horizon$optional
      [1] 0 1 2 3
      
      
      [[1]]$task_ids$location
      [[1]]$task_ids$location$required
      NULL
      
      [[1]]$task_ids$location$optional
       [1] "US" "01" "02" "04" "05" "06" "08" "09" "10" "11" "12" "13" "15" "16" "17"
      [16] "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32"
      [31] "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "44" "45" "46" "47" "48"
      [46] "49" "50" "51" "53" "54" "55" "56" "72"
      
      
      [[1]]$task_ids$target_end_date
      [[1]]$task_ids$target_end_date$required
      NULL
      
      [[1]]$task_ids$target_end_date$optional
       [1] "2022-10-22" "2022-10-29" "2022-11-05" "2022-11-12" "2022-11-19"
       [6] "2022-11-26" "2022-12-03" "2022-12-10" "2022-12-17" "2022-12-24"
      [11] "2022-12-31" "2023-01-07" "2023-01-14" "2023-01-21" "2023-01-28"
      [16] "2023-02-04" "2023-02-11" "2023-02-18" "2023-02-25" "2023-03-04"
      [21] "2023-03-11" "2023-03-18" "2023-03-25" "2023-04-01" "2023-04-08"
      [26] "2023-04-15" "2023-04-22" "2023-04-29" "2023-05-06" "2023-05-13"
      [31] "2023-05-20" "2023-05-27" "2023-06-03" "2023-06-10" "2023-06-17"
      
      
      
      [[1]]$output_type
      [[1]]$output_type$pmf
      [[1]]$output_type$pmf$output_type_id
      [[1]]$output_type$pmf$output_type_id$required
      [1] "low"       "moderate"  "high"      "very high"
      
      [[1]]$output_type$pmf$output_type_id$optional
      NULL
      
      
      [[1]]$output_type$pmf$value
      [[1]]$output_type$pmf$value$type
      [1] "double"
      
      [[1]]$output_type$pmf$value$minimum
      [1] 0
      
      [[1]]$output_type$pmf$value$maximum
      [1] 1
      
      
      
      
      [[1]]$target_metadata
      [[1]]$target_metadata[[1]]
      [[1]]$target_metadata[[1]]$target_id
      [1] "wk flu hosp rate category"
      
      [[1]]$target_metadata[[1]]$target_name
      [1] "week ahead weekly influenza hospitalization rate category"
      
      [[1]]$target_metadata[[1]]$target_units
      [1] "rate per 100,000 population"
      
      [[1]]$target_metadata[[1]]$target_keys
      [[1]]$target_metadata[[1]]$target_keys$target
      [1] "wk flu hosp rate category"
      
      
      [[1]]$target_metadata[[1]]$target_type
      [1] "ordinal"
      
      [[1]]$target_metadata[[1]]$description
      [1] "This target represents a categorical severity level for rate of new hospitalizations per week for the week ending [horizon] weeks after the reference_date, on target_end_date."
      
      [[1]]$target_metadata[[1]]$is_step_ahead
      [1] TRUE
      
      [[1]]$target_metadata[[1]]$time_unit
      [1] "week"
      
      
      
      

