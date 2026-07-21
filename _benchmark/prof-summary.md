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
