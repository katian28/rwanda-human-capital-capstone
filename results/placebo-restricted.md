# Placebo tests, 9-country donor pool (Hodler's published donors, all 9)

**Run date:** 07 October 2026

This is a restricted-pool sensitivity check, not the headline placebo result -- see `results/placebo-full-pool-in-space.csv` / `code/04_placebo_gdp_full_pool.R` for the full 37-country test. In-space placebo uses Hodler's full documented predictor set (PWT 7.1 investment/openness, WDI inflation, Polity, Freedom House, UCDP conflict); the in-time placebo uses simpler GDP-only predictors since UCDP conflict data doesn't exist before 1989 and cannot be shifted back to a fake 1985 treatment's pre-period.

## In-space placebo

| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |
|------|------|-----------|------------|-------|
| 1 | SDN | 0.0544 | 0.8772 | 16.13 |
| 2 | SEN | 0.0509 | 0.5838 | 11.48 |
| 3 | RWA | 0.0421 | 0.3440 | 8.17 |
| 4 | MLI | 0.0940 | 0.4286 | 4.56 |
| 5 | LSO | 0.0918 | 0.3981 | 4.34 |
| 6 | CMR | 0.0585 | 0.1964 | 3.36 |
| 7 | GAB | 0.1034 | 0.2951 | 2.85 |
| 8 | NER | 0.1224 | 0.3257 | 2.66 |
| 9 | COG | 0.1467 | 0.3486 | 2.38 |
| 10 | LBR | 2.3249 | 0.6422 | 0.28 |

**Rwanda's rank: 3 of 10 (p = 0.300).**

## In-time placebo (fake treatment year: 1985)

- Pre-1985 RMSPE: 0.0509
- 1985-1993 (placebo post) RMSPE: 0.0688
- Ratio: 1.35
