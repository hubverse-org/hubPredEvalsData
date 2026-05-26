# hubPredEvalsData (development version)

## New Features

* Added optional scale-transformation support to `predevals-config.yml` via schema version `v1.1.0` (#39):
  * `transform_defaults` — top-level default transform applied to all transformable targets.
  * `targets[*].transform` — per-target transform that overrides `transform_defaults`, or the literal `false` to opt a target out.
  * Supported transform functions: `log_shift`, `sqrt`, `log1p`, `log`, `log10`, `log2`.
* Configured transforms are now applied during scoring (#40).
* `scores.csv` is now emitted in wide format, with transformed-scale metrics as `<metric>__<label>`-suffixed columns (e.g. `wis__log`). Setting `append: false` emits only the suffixed columns.
* Existing v1.0.1 configs continue to validate against v1.1.0 without changes.
* Added `generate_predevals_options()`, which assembles the contents of the `predevals-options.json` file used to initialise the predevals dashboard. It returns the validated config with each target's `metrics` expanded to the columns present in `scores.csv` (relative-skill metrics, plus transformed-scale `<metric>__<label>` metrics when a transform applies) and a resolved `transform` block attached (#41, closes #4).
* `generate_eval_data()` now discovers oracle output from `hub_path` via `hubData::connect_target_oracle_output()` when `oracle_output` is not supplied; the argument remains supported for back-compat (#51).

## Bug Fixes

* `generate_eval_data()` no longer fails on ordinal pmf targets that request `rps`. The ordinal level order is now read from the hub's `tasks.json` and forwarded to `hubEvals::score_model_out()` so scoringutils dispatches the data as ordinal (#48).
* `read_predevals_config()` now warns when an ordinal-only pmf metric (e.g. `rps`) is requested against a pre-v4 tasks-schema (where `output_type_id` is split across `required`/`optional`), and errors if the hub's pmf `output_type_id$optional` is non-empty (#48).

# hubPredEvalsData 1.0.0

This is a **breaking change** release that adds support for hubs with multiple rounds.

## Breaking Changes

* Configuration files now require schema version `1.0.1` and a new `rounds_idx` property.

## How to Update

1. Update your config file's `schema_version` to:
   ```yaml
   schema_version: https://raw.githubusercontent.com/hubverse-org/hubPredEvalsData/main/inst/schema/v1.0.1/config_schema.json
   ```

2. Add the `rounds_idx` property after `schema_version`, specifying which round to use (0-based index):
   ```yaml
   rounds_idx: 0
   ```

## New Features

* Added `rounds_idx` configuration property to specify which round entry to use from the hub's `tasks.json` file (#26).
* Hubs with multiple rounds are now supported.

---

# hubPredEvalsData 0.0.0.9000

* Initial development version.
