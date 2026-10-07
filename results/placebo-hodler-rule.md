# Full-pool GDP placebo test with Hodler's exclusion rule applied

**Run date:** 07 October 2026

## Rule

Per `docs/replication-feasibility.md`, Hodler excludes placebo units whose own pre-treatment RMSPE exceeds the placebo group's median plus one standard deviation (threshold here: 0.4434). This is the paper's own pre-specified rule, applied here to the full 39-country placebo test from `code/04_placebo_gdp_full_pool.R`.

## Result

Dropped 1 units for poor pre-treatment fit: NGA.
**Rwanda's rank barely changes: 20 of 29 (p = 0.690), versus 20 of 30 (p = 0.667) without the rule.**

## Why the rule doesn't help

The units that outrank Rwanda (GNQ, MRT, MDG, GMB, ETH) all have GOOD pre-treatment fits -- several fit their own pre-1994 path better than Rwanda's synthetic control fits Rwanda's. Their extreme ratios come from large, unrelated POST-period volatility (GNQ is the standout case: pre-treatment RMSPE 0.0781, post-treatment RMSPE 39.7). Hodler's rule filters units with bad PRE-treatment fit; it does not filter units whose post-treatment period happens to be volatile for reasons unrelated to the 1994 genocide. The two problems are different, and this rule only solves the first one.

## Interpretation

This was tested, not assumed: applying the original paper's own documented exclusion rule does not rescue the full-pool placebo result. Reporting this honestly is more informative than either omitting the check or searching for a different exclusion rule that happens to produce a better-looking rank.
