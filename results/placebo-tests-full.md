# Placebo tests, full Sub-Saharan Africa donor pool

**Run date:** 19 September 2026

## Donor pool construction

Sub-Saharan Africa (World Bank classification) minus Rwanda (treated) and Burundi, DRC, Tanzania, and Uganda (excluded for spillover risk, per `docs/replication-feasibility.md`) gives 43 candidates. Screening for complete PWT 8.0 `rgdpe` coverage over 1970-2011 leaves 39 eligible donors.
Dropped for incomplete `rgdpe` coverage: ERI, SYC, SOM, SSD.

## In-space placebo (full pool)

Each of the 40 units (Rwanda plus 39 donors) is reassigned as the treated unit in turn, fit against the remaining units in the pool, and ranked by post/pre RMSPE ratio.

**Top 10 by ratio:**

| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |
|------|------|-----------|------------|-------|
| 1 | GNQ | 0.0756 | 39.6765 | 524.66 |
| 2 | GIN | 0.0049 | 0.9532 | 194.74 |
| 3 | MRT | 0.0214 | 2.4374 | 114.04 |
| 4 | GMB | 0.0143 | 1.5882 | 111.40 |
| 5 | MDG | 0.0203 | 2.1959 | 108.15 |
| 6 | SLE | 0.0152 | 0.8684 | 57.29 |
| 7 | COM | 0.0156 | 0.8024 | 51.52 |
| 8 | ETH | 0.0477 | 1.7494 | 36.67 |
| 9 | CPV | 0.0313 | 0.8677 | 27.69 |
| 10 | ZWE | 0.0297 | 0.7458 | 25.08 |

**Rwanda's rank: 20 of 40 (p = 0.500).**
This does not clear the conventional 10% rank-based placebo threshold. Expanding the donor pool weakens, rather than strengthens, the placebo case relative to the 9-country version — report this directly rather than reverting to the smaller pool to get a better-looking rank.

## In-time placebo (fake treatment year: 1985), full pool

- Pre-1985 RMSPE: 0.0222
- 1985-1993 (placebo post) RMSPE: 0.1125
- Ratio: 5.07

## Comparison to the 9-country version

See `results/placebo-tests.md` for the 9-country donor pool (published-weight countries only), where Rwanda ranked 3rd of 10 (p = 0.30) in-space and showed an in-time ratio of 4.27. Report both versions in the paper; do not present only the more favorable one.
