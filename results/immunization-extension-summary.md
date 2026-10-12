# Immunization coverage extension: results

**Run date:** 8 October 2026 (supersedes the 6 October version, which used only lagged-outcome special predictors, no external covariates)

Public-health service-delivery recovery extension (`code/12_immunization_extension.R`), DTP3 coverage, 18-country Sub-Saharan Africa donor pool. See `docs/data-availability.md` for why this replaced `hc` as the extension outcome.

## Predictors: three lagged-outcome, plus three external

The main fit uses three lagged-DTP3-coverage special predictors (1981-1985, 1986-1989, 1990-1993 averages) plus three external predictors averaged over 1989-1993: MCV1 (measles) coverage, same WHO/UNICEF WUENIC source as DTP3; UCDP conflict (battle deaths), a direct mechanism for vaccine-delivery disruption; and GDP per capita (PWT `rgdpe`/`pop`), a health-financing proxy. An earlier version used only the lagged-outcome predictors; adding the three external ones brings this extension's rigor in line with the GDP replication's own use of real external covariates.

GDP per capita has zero PWT coverage for Somalia and Seychelles (confirmed directly, not a window gap -- no rows at all), so both are dropped from the donor pool. This also resolves, at the data-sourcing stage, an earlier problem where Somalia's unusually low baseline mechanically dominated the synthetic control's weights under a now-superseded normalized specification -- raw percentage-point levels were adopted for that reason, and Somalia's exclusion here is a second, independent fix to the same underlying issue.

## Main result (raw percentage points)

- Donor weights: Swaziland (SWZ) 87%, Republic of the Congo (COG) 9.3%, Lesotho (LSO) 3.7% -- three donors, nothing on Somalia or any other donor. (`results/immunization-extension-weights.csv`)
- Pre-treatment RMSPE: 9.00 percentage points.
- 1994 gap: **-68.9 percentage points** (actual 23%, synthetic 91.9%), matching the raw 83%->23% crash.
- Average post-treatment gap: **+3.1 percentage points** -- positive. Rwanda's actual coverage runs above its synthetic counterfactual on average after 1994; the 2011 gap is +6.6.
- The path (`figures/immunization-extension-path.png`) shows a sharp one-year collapse, fast recovery, and Rwanda's actual coverage **overtaking** its synthetic counterfactual from 1995 onward in most years -- consistent with Rwanda's well-documented post-genocide health-system investment pushing coverage to near-universal (~97%) by the late 2000s, while the donor-pool synthetic stays in the mid-to-high 80s.

## Placebo result

**Rwanda's rank: 12 of 19 (p = 0.632).** This is weaker than an earlier, less complete specification's 10 of 21 (p = 0.476) -- adding the three external predictors was motivated by specification fidelity, not by searching for a better number, and it moved the result in the less favorable direction. Still does not support a strong standalone causal claim from the placebo test alone, consistent with how the GDP section reports its own full-pool result without overclaiming -- but the raw path, especially the post-1995 overtake, remains a striking descriptive finding independent of the placebo test's verdict.

## Files

`results/immunization-extension-path.csv`, `results/immunization-extension-weights.csv`, `results/immunization-extension-placebo.csv`, `figures/immunization-extension-path.png`, `figures/immunization-extension-gaps.png` -- current result. The earlier Somalia-exclusion robustness check (`code/13`) was removed on 10 October 2026 once it became redundant with the main fit's own donor pool; it remains recoverable from git history.
