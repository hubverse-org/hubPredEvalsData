# read_predevals_config warns on ordinal pmf rps under pre-v4 schema

    Scoring "rps" on ordinal pmf target "hosp rate category": the hub's tasks-schema is "v3.0.0" and its pmf output_type_id$optional is empty, so output_type_id$required is taken as the ordinal level order.
    i Upgrade the hub's tasks-schema to v4.0.0+ to make the level order explicit and silence this warning.

# read_predevals_config errors when pre-v4 ordinal pmf has non-empty $optional

    Error in predevals config file:
    Cannot score "rps" on ordinal pmf target "hosp rate category" under tasks-schema "v3.0.0".
    x A definitive ordinal level order cannot be determined when output_type_id$optional is non-empty ("very high").
    i Bump the hub's tasks-schema to v4.0.0+ (where pmf output_type_id is a single `required` array) to disambiguate ordinal level order.

