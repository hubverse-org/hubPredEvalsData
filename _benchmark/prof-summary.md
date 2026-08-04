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

## Connect once + oracle subset (#82) — `ak/connect-once/82`, hubEvals 0.4.0, scoringutils 2.2.0

554 s wall-clock, down from 583 s at the same hubEvals. Memory flat (R heap
~4.0 GB, Arrow ~1.15 GB; unchanged, because the collect-once hoist was
deliberately not done). These are the `gc()`/Arrow-pool peaks, not the
`/usr/bin/time -l` RSS the baseline reports, so not comparable to that 6.85 GB.

The ~29 s saving is on the load-and-join side, not the statistics. The hub
connection is opened once and reused (3 `connect_hub()` calls → 1 for this
one-target config), and the oracle is subset to the target before scoring, so
each `score_model_out()` join drops the other target's oracle rows:
`get_and_save_scores` falls 592 → 566 s, within it `score()` 171 → 163 s. The
relative-skill path is untouched by #82 and still dominates (~57%); the small
differences there (356.5 → 344.7 s) are run-to-run `forderv` noise, not a shape
change. The pairwise merge remains the top cost, for #83 / hubEvals#144.
