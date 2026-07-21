# Benchmark

A repeatable measurement of `generate_eval_data()` for the performance work in
[#80](https://github.com/hubverse-org/hubPredEvalsData/issues/80), so
optimisations are measured rather than assumed.

Not part of the package: `_benchmark/` is `.Rbuildignore`d.

## Running it

Needs a local clone of
[`cdcepi/FluSight-forecast-hub`](https://github.com/cdcepi/FluSight-forecast-hub):

```sh
HUBPREDEVALS_BENCHMARK_HUB=/path/to/FluSight-forecast-hub \
  Rscript _benchmark/run-benchmark.R
```

The package is loaded with `pkgload::load_all()`, so it measures the working
tree, not the installed version.

For true peak RSS, which is what decides whether a change fits the runner's
memory, wrap it:

```sh
HUBPREDEVALS_BENCHMARK_HUB=... /usr/bin/time -l Rscript _benchmark/run-benchmark.R
```

## Benchmarking a dependency

Most of the runtime is in the dependencies, not this package: scoring and
relative skill live in `hubEvals`, and the pairwise-comparison merging under
that in `scoringutils`. To measure a change in either, point these at a local
checkout and they are loaded in dependency order, so a dev `scoringutils` runs
under a dev `hubEvals` under this package's working tree:

```sh
HUBPREDEVALS_BENCHMARK_HUB=... \
  HUBPREDEVALS_BENCHMARK_HUBEVALS=/path/to/hubEvals \
  HUBPREDEVALS_BENCHMARK_SCORINGUTILS=/path/to/scoringutils \
  Rscript _benchmark/run-benchmark.R
```

Unset, each dependency is taken from the installed library.

## Labelling runs

Each run records what it measured, so `results.csv` rows stay interpretable:

- `label` — the run's name. Set `HUBPREDEVALS_BENCHMARK_LABEL` to name it after
  the change under test (e.g. `p3-test-type-null`); defaults to this package's
  git id.
- `hubevals`, `scoringutils` — each dependency's git id.

A git id is `branch@sha`, suffixed `-dirty` when the working tree has
uncommitted changes. Since `load_all` measures the working tree, the `-dirty`
marker is what flags a run that a sha alone can't reproduce, so name such runs
via `HUBPREDEVALS_BENCHMARK_LABEL`. An installed dependency records
`version@sha` (from the sha pak/remotes bakes into `DESCRIPTION`), or just the
version for a plain install that carries no sha.

`results.csv` is committed as a record of baselines. Numbers are only comparable
within a machine, so the `sysname` / `machine` / `r_version` columns tell runs
apart.

`Rprof.out` (the raw profile, ~18 MB) and any `*.log` are regenerated on every
run and are git-ignored.

## Where the time goes

`results.csv` is the per-run numbers; [`prof-summary.md`](prof-summary.md) is the
curated record of *where* the time goes and how that shape shifts as the work in
#80 lands. Each run prints its own `Rprof` breakdown, so add to `prof-summary.md`
only when a run moves a cost, removes one, or surfaces a new hotspot, not for
every run.

## The config

`predevals-config.yml` is derived from the live FluSight dashboard config
([`reichlab/flusight-dashboard`](https://github.com/reichlab/flusight-dashboard/blob/main/predevals-config.yml)),
trimmed so a run takes minutes rather than the ~1.5 h a full build needs.

The hub's model-output is left alone: its volume (1.5 GB, 95 models, ~4118
files) is what makes this a realistic test. Only the config is cut, since those
axes multiply the work without changing where the time goes:

- **one target** (`wk inc flu hosp`) rather than two;
- **two metrics** (`wis`, `interval_coverage_95`) plus one relative metric
  (`wis`), keeping one quantile and one coverage metric;
- **three eval_sets** rather than twelve: two 2024-2025 season sets (state and
  national) and one `n_last` set, so the over-read described in P5 stays
  measurable.

All four `disaggregate_by` variables are kept deliberately. The per-`by` loop is
what P2 targets, so cutting it would hide the redundancy the benchmark exists to
measure.

Being a fixed file matters: baselines are only comparable if the config doesn't
move. Regenerating it from upstream would drift as the dashboard gains seasons.

## What it reports

- **wall-clock**;
- **R heap peak**, from `gc()` max-used counters;
- **Arrow pool peak**, tracked separately because Arrow allocates off the R heap
  and so is invisible to `gc()`;
- a **profile** of where time went, from `Rprof`, filtered to entries taking at
  least 1% of total time. This is what gives the load vs score vs write split.
