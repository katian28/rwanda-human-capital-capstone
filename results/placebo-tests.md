# Placebo tests, 9-country donor pool (Synth package)

**Run date:** 24 September 2026

This is a restricted-pool sensitivity check, not the headline placebo result -- see `results/synth-package-placebo-full-pool.csv` / `code/10` for the full 39-country test. Both in-space and in-time tests here use the actual `Synth` package.

## In-space placebo

| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |
|------|------|-----------|------------|-------|
| 1 | SDN | 0.0508 | 0.8160 | 16.06 |
| 2 | RWA | 0.0458 | 0.3382 | 7.38 |
| 3 | SEN | 0.0757 | 0.3060 | 4.04 |
| 4 | CMR | 0.0593 | 0.1640 | 2.77 |
| 5 | MLI | 0.1061 | 0.2845 | 2.68 |
| 6 | COG | 0.1467 | 0.3485 | 2.38 |
| 7 | LSO | 0.1010 | 0.2257 | 2.24 |
| 8 | NER | 0.1310 | 0.2741 | 2.09 |
| 9 | GAB | 0.1328 | 0.2579 | 1.94 |
| 10 | LBR | 2.3249 | 0.6422 | 0.28 |

**Rwanda's rank: 2 of 10 (p = 0.200).**

## In-time placebo (fake treatment year: 1985)

- Pre-1985 RMSPE: 0.0347
- 1985-1993 (placebo post) RMSPE: 0.0817
- Ratio: 2.36
