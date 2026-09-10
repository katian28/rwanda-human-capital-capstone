# Human-capital outcome feasibility

**Decision:** REDESIGN the extension; do not abandon the project

**Evidence date:** 9 September 2026

## Bottom line

The proposed extension remains feasible, but **current WDI gross secondary enrollment cannot serve as the primary outcome in a conventional balanced-panel synthetic-control design**. Rwanda is missing 1994–1998 and most plausible donors are missing different years. PWT 8.0 human capital is technically feasible for the original annual panel, while Barro–Lee is available only at five-year intervals and is better treated as a low-frequency sensitivity analysis.

Recommended design:

1. use PWT 8.0 human capital (`hc`) as the primary technically feasible extension, with careful language about what the constructed index measures;
2. use WDI/UIS secondary enrollment as a secondary post-1999 analysis or move to a missing-data-capable estimator after advisor approval;
3. use Barro–Lee attainment only as low-frequency corroboration.

## WDI secondary enrollment: fails the balanced-panel screen

The World Bank indicator [`SE.SEC.ENRR`](https://data.worldbank.org/indicator/SE.SEC.ENRR?locations=RW), sourced from UNESCO UIS, is public and accessible through the [World Bank API](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392). An all-country API audit found:

- Rwanda has 18 observed pre-treatment years: 1971 and 1976–1992.
- Rwanda has 13 observed post-treatment years: 1999–2011.
- Rwanda is missing 1994–1998, so the series cannot measure the immediate education response.
- Nineteen of 43 eligible Sub-Saharan African donors have at least 12 pre-1994 and eight post-1998 observations.
- Only **Lesotho** is complete for every year in Rwanda’s continuous 1976–1992 and 1999–2011 windows.
- The same one-donor result holds when the pre-period is shortened to 1980–1992 or 1985–1992.

Published GDP-donor counts for 1970–1993/1994–2011 are: Cameroon 22/16; Republic of the Congo 22/5; Gabon 19/7; Liberia 8/3; Lesotho 23/18; Mali 22/16; Niger 20/16; Sudan 0/11; and Senegal 16/13.

This is insufficient for standard `Synth` estimation on a continuous balanced outcome panel. Interpolating outcomes merely to satisfy software would add strong assumptions and is not recommended by default.

The [UIS Data Browser](https://databrowser.uis.unesco.org/resources/bulk) offers current bulk files and an API. Its archive should still be checked for observations or vintages not propagated to WDI, but a different interface should not be presumed to solve genuine reporting gaps.

## PWT 8.0 human capital: technically feasible, conceptually limited

The exact [PWT 8.0](https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt8.0?lang=en) release used by Hodler contains annual `hc` values for Rwanda and 27 eligible donors throughout 1970–2011. This passes the balanced-panel availability screen and preserves the original treatment date and donor logic.

The limitation is interpretation. PWT human capital is a constructed stock index based on schooling and assumed returns, with interpolation and smoothing in the underlying inputs. It may respond slowly to an abrupt loss of people and schooling. Hodler used it as a predictor, not an outcome. Results should be framed as the path of a modeled human-capital stock index, not a direct measure of learning or educated people lost.

## Barro–Lee: too coarse for the primary dynamic design

The [Barro–Lee dataset](https://barrolee.github.io/BarroLeeDataSet/) and [version 3 documentation](https://github.com/barrolee/BarroLeeDataSet/blob/master/BLv3.md) are openly downloadable. A direct audit of `BL_v3_MF1564.csv` confirmed Rwanda observations at five-year intervals from 1950 through 2015, including 1970, 1975, 1980, 1985, 1990, 1995, 2000, 2005, 2010, and 2015.

This provides only five pre-treatment points from 1970–1990 and places the first post-treatment point in 1995. The dataset also uses filling and extrapolation. It can corroborate long-run attainment but cannot identify annual recovery timing with Hodler’s precision.

## Defensible options

**Recommended:** retain the capstone and define the extension as the effect on PWT 8.0 `hc`. Use WDI enrollment descriptively from 1999 and Barro–Lee as a five-year robustness outcome.

**Higher method risk:** keep enrollment primary but use an estimator designed for incomplete panels, such as an explicitly justified generalized or augmented synthetic-control or matrix-completion method. This changes the method and requires advisor approval and strong diagnostics.

**Change only the extension:** if the course requires the same conventional estimator and an annual observed education outcome, replace secondary enrollment with an outcome that passes a frozen donor-coverage screen. Keep the GDP replication.

## Deadlines

- **10 September:** choose with the advisor between PWT `hc` and a missing-data-capable enrollment design.
- **11 September:** produce the published-weight GDP reconstruction and first PWT `hc` coverage file.
- **12 September:** run a pre-treatment-only fit diagnostic; do not inspect post-treatment results while tuning.
- **13 September:** freeze the outcome, exclusions, period, estimator, and missing-data rule in a design memo.

Proceed only if pre-treatment fit is credible and placebo inference leaves a meaningful comparison set. Otherwise, change the extension outcome—not the entire capstone question.
