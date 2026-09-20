# Robustness: Barro-Lee attainment and WDI secondary enrollment

**Run date:** 20 September 2026

Both checks are descriptive corroboration, not synthetic-control estimates -- per `docs/data-availability.md`, Barro-Lee's five-year frequency cannot resolve annual recovery timing, and WDI enrollment is missing Rwanda 1994-1998 so cannot support a balanced-panel design. Comparison countries are the donors that already carried the most weight in this project's GDP re-estimation (code/02) and human-capital extension (code/05): Cameroon, Senegal, Zambia, Mali, Cote d'Ivoire, Niger, Mozambique, South Africa.

## Barro-Lee mean years of schooling (ages 15-64), five-year intervals

Rwanda's average years of schooling: 2.28 in 1990, 2.84 in 1995 (change: +0.56). The 1995 observation is the first data point after the genocide at this frequency; the true 1994 low point cannot be resolved.

**1990-to-1995 change, Rwanda vs. comparators:**

| Country | 1990 | 1995 | Change |
| --- | --- | --- | --- |
| Rwanda | 2.28 | 2.84 | +0.56 |
| Cameroon | 4.65 | 5.30 | +0.65 |
| Senegal | 2.37 | 2.26 | -0.11 |
| Zambia | 5.02 | 6.03 | +1.01 |
| Mali | 0.95 | 1.07 | +0.12 |
| Cote d'Ivoire | 2.79 | 3.46 | +0.67 |
| Niger | 1.08 | 1.28 | +0.20 |
| Mozambique | 1.06 | 0.98 | -0.08 |
| South Africa | 6.89 | 8.37 | +1.47 |

Rwanda's 1990-1995 change (+0.56) is within the comparator range (-0.11 to +1.47). Since Barro-Lee attainment is built from census/survey data with substantial interpolation between rounds, a five-year change of this size is not strong evidence either way -- it is consistent with, but does not confirm, the flat/positive PWT `hc` result in Section 4.

## WDI secondary enrollment (descriptive, 1990-2011)

Rwanda is missing 1994, 1995, 1996, 1997, 1998 (confirming the balanced-panel audit in `docs/data-availability.md`). From 1999 onward, Rwanda's gross secondary enrollment rises from single digits to the mid-30s by 2011 (see `results/robustness-wdi-enrollment.csv` and the figure) -- a visible recovery trajectory, but the series cannot speak to the 1994-1998 period at all, so it cannot corroborate or contradict a 1994 shock directly.

## Interpretation

Neither check moves the paper's conclusions on its own. Barro-Lee is too coarse and too smoothed by interpolation to add power beyond the PWT `hc` result; WDI enrollment simply cannot see the years that matter. Both are included because the paper's own design documents (`docs/data-availability.md`) committed to reporting them, not because either is informative on its own -- this should be stated plainly in the paper rather than presented as if it strengthens the case.
