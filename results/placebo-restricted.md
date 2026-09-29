# Placebo tests, 9-country donor pool

**Run date:** 28 September 2026

This is a restricted-pool sensitivity check, not the headline placebo result -- see `results/placebo-full-pool-in-space.csv` / `code/04_placebo_gdp_full_pool.R` for the full 39-country test.

## In-space placebo

| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |
|------|------|-----------|------------|-------|
| 1 | SDN | 0.0534 | 0.8255 | 15.47 |
| 2 | SEN | 0.0692 | 0.6055 | 8.75 |
| 3 | RWA | 0.0555 | 0.3210 | 5.78 |
| 4 | CMR | 0.0585 | 0.1964 | 3.36 |
| 5 | MLI | 0.1059 | 0.2941 | 2.78 |
| 6 | NER | 0.1273 | 0.3208 | 2.52 |
| 7 | COG | 0.1467 | 0.3486 | 2.38 |
| 8 | GAB | 0.1286 | 0.2539 | 1.97 |
| 9 | LSO | 0.1060 | 0.1740 | 1.64 |
| 10 | LBR | 2.3249 | 0.6422 | 0.28 |

**Rwanda's rank: 3 of 10 (p = 0.300).**

## In-time placebo (fake treatment year: 1985)

- Pre-1985 RMSPE: 0.0509
- 1985-1993 (placebo post) RMSPE: 0.0688
- Ratio: 1.35
