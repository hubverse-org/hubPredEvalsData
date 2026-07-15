# Generate the contents of the `predevals-options.json` file

Assembles the contents of the `predevals-options.json` file that
initialises the predevals dashboard. The dashboard reads this file on
load to build its menus and labelling: which targets and evaluation sets
a user can select, which metrics can be displayed for each target, which
task-id variables the scores can be disaggregated by, and the
human-readable text for task-id values. It is the dashboard's index of
what can be shown; the score values themselves come from the per-target
`scores.csv` files written by
[`generate_eval_data()`](https://hubverse-org.github.io/hubPredEvalsData/reference/generate_eval_data.md).

## Usage

``` r
generate_predevals_options(hub_path, config_path)
```

## Arguments

- hub_path:

  A path to the hub.

- config_path:

  A path to a yaml file that specifies the configuration options for the
  evaluation.

## Value

The predevals config as a list, with each entry of `targets` augmented
as described above.

## Details

The result is the validated predevals config with each entry of
`targets` augmented with the metric and transform metadata the dashboard
needs to populate its metric selector:

- `target_name` and `target_units`: the human-readable target name and
  unit of observation from the hub's tasks.json `target_metadata`,
  spliced in just after `target_id`. `target_name` is used by the
  dashboard to label target menu items (falling back to `target_id` when
  absent). `target_units` is passed through so the dashboard can, in
  future, label the scale of unit-valued scores (e.g. WIS, ae_median,
  interval widths); it is not yet consumed. Both are required
  `target_metadata` properties in every tasks-schema version, so they
  are always present.

- `metrics`: the metric columns present in the target's `scores.csv`, in
  column order. A `<metric>_scaled_relative_skill` entry is spliced in
  before each metric listed in `relative_metrics`. When a transform
  applies, the transformed-scale `<metric>__<label>` columns are
  appended, or replace the natural-scale columns when `append: false`.
  Transform-invariant metrics (`interval_coverage_<n>`, `bias`) are
  unchanged by any monotonic transform and so always appear only under
  their natural-scale name. This is the list the dashboard iterates to
  build its metric selector.

- `transform`: the resolved transform for the target (with
  `transform_defaults` inheritance applied), as a list with `fun`,
  `label`, `append` and a composed human-readable `description` the
  dashboard can show to explain the transformed scale to the user. The
  key is absent when no transform applies, including targets that opt
  out with `transform: false` and targets whose available output types
  are all non-transformable (where the transform is skipped at scoring
  time).

The config is read via
[`read_predevals_config()`](https://hubverse-org.github.io/hubPredEvalsData/reference/read_predevals_config.md),
so the config schema and transform validation run as a side effect. The
caller decides where to write the result.
