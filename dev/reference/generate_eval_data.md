# Generate evaluation data for a hub

Scores each target configured in the predevals config against its oracle
data and writes wide-format score tables to disk.

## Usage

``` r
generate_eval_data(hub_path, config_path, out_path, oracle_output = NULL)
```

## Arguments

- hub_path:

  A path to the hub.

- config_path:

  A path to a yaml file that specifies the configuration options for the
  evaluation.

- out_path:

  The directory to write the evaluation data to.

- oracle_output:

  Optional data frame of oracle output to use for the evaluation. When
  `NULL` (the default), oracle output is discovered from `hub_path` via
  [`hubData::connect_target_oracle_output()`](https://hubverse-org.github.io/hubData/reference/connect_target_oracle_output.html).
  Supplying a pre-loaded data frame remains supported for back-compat
  with callers that load oracle data themselves.

## Output

For each `(target, eval_set, disaggregation)` requested in the config, a
`scores.csv` is written under
`out_path/<target_id>/<eval_set_name>[/<by>]/` in wide format, with one
row per model per disaggregation key.

When a target has a configured transform, transformed-scale metrics
appear as `<metric>__<label>`-suffixed columns (e.g. `wis__log`)
alongside the natural-scale columns. Setting `append: false` emits only
the suffixed columns. Transform-invariant metrics
(`interval_coverage_<n>` and `bias`, whose values are unchanged by any
monotonic transform) always appear only under their natural-scale name
regardless of `append`.

For the full configuration schema, see the JSON Schema files installed
with the package under
`system.file("schema", package = "hubPredEvalsData")`.
