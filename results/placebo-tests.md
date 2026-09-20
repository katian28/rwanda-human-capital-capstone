# Placebo tests and RMSPE-based inference

**Run date:** 19 September 2026

## In-space placebo (donor permutations)

Each donor country is treated as if it were the treated unit, using the remaining 8 donors (Rwanda excluded) as its synthetic control, over the same 1970-1993 pre-period. Ranking all 9 units plus Rwanda by post/pre RMSPE ratio gives a permutation-style p-value (rank / number of units).

| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |
|------|------|-----------|------------|-------|
| 1 | SDN | 0.0485 | 0.7942 | 16.36 |
| 2 | SEN | 0.0509 | 0.5838 | 11.48 |
| 3 | RWA | 0.0421 | 0.3539 | 8.41 |
| 4 | MLI | 0.0940 | 0.4286 | 4.56 |
| 5 | LSO | 0.0917 | 0.4073 | 4.44 |
| 6 | CMR | 0.0585 | 0.1964 | 3.36 |
| 7 | GAB | 0.1033 | 0.2938 | 2.84 |
| 8 | NER | 0.1224 | 0.3270 | 2.67 |
| 9 | COG | 0.1467 | 0.3486 | 2.38 |
| 10 | LBR | 2.3249 | 0.6422 | 0.28 |

**Rwanda's rank: 3 of 10 (p = 0.300).** 
Rwanda is not the most extreme unit (2 placebo unit(s) show a larger ratio). This weakens (without eliminating) the inferential case relative to a rank-1 result and should be reported honestly rather than reframed.

**Caveat:** this uses the same 9-country donor pool as the published weights, not the full ~39-country Sub-Saharan Africa donor pool described in `docs/replication-feasibility.md`. A larger placebo pool is a follow-up robustness check, not required for this checkpoint.

## In-time placebo (fake treatment year: 1985)

Fitting a synthetic Rwanda on 1970-1984 only and checking for a spurious gap between 1985 and 1993 (before the real 1994 genocide):

- Pre-1985 RMSPE: 0.0244
- 1985-1993 (placebo post) RMSPE: 0.1041
- Ratio: 4.27

The ratio is non-trivial, suggesting some divergence between Rwanda and its synthetic control even before 1994. This should be reported and discussed as a limitation rather than omitted.

## Still not done (flagged, not blocking this checkpoint)

- Full ~39-country Sub-Saharan Africa donor pool for in-space placebos (currently limited to the 9 published-weight donors).
- Placebo tests using the re-estimated (rather than published) donor weights.
- Formal confidence intervals beyond the rank-based p-value.
