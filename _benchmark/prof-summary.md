# Profile summary

Where the benchmark run spends its time, and how that shifts as the
optimisation work in [#80](https://github.com/hubverse-org/hubPredEvalsData/issues/80)
lands.

`results.csv` records the numbers for every run; this file is curated. Add an
entry only when a run meaningfully changes the *shape* of the profile (a cost
moves, disappears, or a new hotspot surfaces), not for every run. Each run
prints its own `Rprof` breakdown, so this is the place to record the ones worth
remembering.

## Baseline — `a6257af`, hubEvals 0.3.0.9000, scoringutils 2.2.0

647 s wall-clock, peak RSS 6.85 GB.

| | total | % |
|---|---|---|
| Relative skill (`get_pairwise_comparisons`) | 427.5 s | 62.2% |
| ├─ of which `wilcox.test` | 16.4 s | 2.4% |
| `score()` | 167.5 s | 24.4% |
| Load (`load_model_out_in_eval_set`, all calls) | 32.5 s | 4.7% |
| ├─ of which `collect()` | 22.3 s | 3.2% |
| ├─ of which `connect_hub()` | 3.0 s | 0.4% |
| Write | 0.04 s | ~0% |

Dominant cost is the pairwise comparisons in relative skill, and within them the
merging, not the statistics: `forderv` (data.table ordering, inside
`merge.data.table`, inside `compare_forecasts`) is 43.8% of total self-time on
its own. `wilcox.test` is only 2.4%.

Load is a small fraction, and the collect is already projected to the 9 columns
scoring needs. The write is negligible.

Consequences for the #80 plan are in the issue comments: the merge cost
(hubverse-org/hubEvals#144) is the real prize, P2 (#83) next, load-side work
(#82) is minor.

## hubEvals 0.4.0 — `main@4dd7afb`, hubEvals 0.4.0, scoringutils 2.2.0

583 s wall-clock, down from 647 s. Same package code as the baseline; the only
change is hubEvals 0.3.0.9000 → 0.4.0.

The whole gain is in the pairwise path: relative skill
(`get_pairwise_comparisons`) drops from 427.5 s (62.2%) to 356.5 s (57.1%),
about 71 s. hubEvals 0.4.0 suppresses the wilcoxon tie warnings the pairwise
comparisons raised in bulk, and the warning-handling overhead, not the
`wilcox.test` statistics, was the cost: `wilcox.test` falls below 1% (was 2.4%),
yet the path sheds far more than the 16 s it ever spent computing. `score()`
(171 s) and load are unchanged. `forderv` (data.table ordering inside the merge)
is still the single largest self-time cost, so the merge
(hubverse-org/hubEvals#144) remains the prize.

## Connect once + oracle subset (#82) — `ak/connect-once/82@3e6f669`, hubEvals 0.4.0, scoringutils 2.2.0

569.2 s wall-clock, down from 582.6 s at the same hubEvals. Memory flat (R heap
~3.9 GB, Arrow ~1.16 GB; unchanged, because the collect-once hoist was
deliberately not done). These are the `gc()`/Arrow-pool peaks, not the
`/usr/bin/time -l` RSS the baseline reports, so not comparable to that 6.85 GB.

The saving is on the load-and-join side, not the statistics. The hub connection
is opened once and reused (3 `connect_hub()` calls → 1 for this one-target
config), and the oracle is subset to the target before scoring, so each
`score_model_out()` join drops the other targets' oracle rows: `score()` falls
171 → 162.8 s, reproduced across two runs of this branch.

Wall-clock alone does not resolve this change. The relative-skill path is ~59%
of the run and untouched by #82, and its `forderv` ordering varies by tens of
seconds between runs: 344.7 / 358.1 / 374.1 across three runs of this branch,
against 356.5 on main. An earlier run recorded 553.6 s, which caught a fast
pairwise and so overstated the saving as ~29 s; `score()` is the stable signal.
The pairwise merge remains the top cost, for #83 / hubEvals#144.

## hubEvals 0.5.0 + scoringutils 2.3.0: `ak/release/1.3.0@a529d97`

240.4 s wall-clock, down from 569.2 s. Same package code as the #82 entry (the
release commit changes only `DESCRIPTION` and `NEWS.md`); the only change is
hubEvals 0.4.0 to 0.5.0, which raises scoringutils from 2.2.0 to 2.3.0. Peak RSS
by `/usr/bin/time -l` is 5.09 GB, down from the baseline's 6.85 GB. R heap peak
3.4 GB (was 3.9 GB); Arrow pool peak 1.62 GB (was 1.16 GB).

| | total | % |
|---|---|---|
| `score()` | 187.4 s | 62.4% |
| ├─ of which `assert_forecast` | 75.7 s | 25.2% |
| ├─ of which `apply_metrics` | 72.6 s | 24.2% |
| │  └─ of which `quantile_to_interval` | 70.5 s | 23.5% |
| `transform_quantile_model_out` (`as_forecast_quantile()`) | 66.8 s | 22.2% |
| Load (`load_model_out_in_eval_set`, all calls) | 31.1 s | 10.4% |
| Relative skill (`get_pairwise_comparisons`) | 5.0 s | 1.7% |
| Write | ~0 s | ~0% |

The pairwise merge is gone as a cost. Relative skill falls from 356.5 s (57.1%)
to 5.0 s (1.7%) and `merge.data.table` to 0.7 s: this is
hubverse-org/hubEvals#144 landing, through scoringutils 2.3.0.

`forderv` is still the single largest self-time cost (31.2%), but it has moved.
Two thirds of its samples now sit under `score()`: half under
`quantile_to_interval` inside `apply_metrics` (`wis` and `interval_coverage_95`
both convert the quantile forecast to intervals), a quarter under
`assert_forecast`. The remaining third is under `transform_quantile_model_out`,
in `as_forecast_quantile()` validation. None of it is in the pairwise path.

`score()` reads 187.4 s against 162.8 s in the #82 entry. Whether that is
scoringutils 2.3.0 or run-to-run variance is unresolved from a single run.

Load is unchanged in absolute terms (31.1 s against 32.5 s at baseline) and so
is now a tenth of the run rather than a twentieth. With relative skill gone the
run is score-bound, and the remaining hotspots (forecast validation, the
quantile-to-interval ordering, the `as_forecast_quantile()` conversion) are all
upstream of this package.

Note that `results.csv` also holds a run of the same stack in the amd64 dev
image under emulation on this machine (472.5 s). It is not comparable with the
native rows and records only that the stack installs and runs in the image.
