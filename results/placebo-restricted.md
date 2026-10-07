# Placebo tests, 9-country donor pool (Liberia dropped -- see header)

**Run date:** 07 October 2026

This is a restricted-pool sensitivity check, not the headline placebo result -- see `results/placebo-full-pool-in-space.csv` / `code/04_placebo_gdp_full_pool.R` for the full 39-country test. In-space placebo uses Hodler's full documented predictor set (PWT 7.1 investment/openness, WDI inflation, Polity, Freedom House, UCDP conflict); the in-time placebo uses simpler GDP-only predictors since UCDP conflict data doesn't exist before 1989 and cannot be shifted back to a fake 1985 treatment's pre-period.

## In-space placebo

| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |
|------|------|-----------|------------|-------|
| 1 | SDN | 0.0491 | 0.8394 | 17.09 |
| 2 | SEN | 0.0552 | 0.5967 | 10.80 |
| 3 | RWA | 0.0495 | 0.3504 | 7.08 |
| 4 | MLI | 0.0940 | 0.4286 | 4.56 |
| 5 | LSO | 0.0917 | 0.4073 | 4.44 |
| 6 | CMR | 0.0585 | 0.1964 | 3.36 |
| 7 | GAB | 0.1034 | 0.2951 | 2.85 |
| 8 | COG | 0.1555 | 0.2976 | 1.91 |
| 9 | NER | 0.2641 | 0.4384 | 1.66 |

**Rwanda's rank: 3 of 9 (p = 0.333).**

## In-time placebo (fake treatment year: 1985)

- Pre-1985 RMSPE: 0.0277
- 1985-1993 (placebo post) RMSPE: 0.1116
- Ratio: 4.03
