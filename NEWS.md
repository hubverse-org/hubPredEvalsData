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
