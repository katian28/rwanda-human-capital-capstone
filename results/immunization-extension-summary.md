# Immunization coverage extension: results

**Run date:** 6 October 2026 (supersedes the 1 October version, which used normalized ratios)

Public-health service-delivery recovery extension (`code/12_immunization_extension.R`), DTP3 coverage, 20-country Sub-Saharan Africa donor pool with complete 1981-2011 data. See `docs/data-availability.md` for why this replaced `hc` as the extension outcome.

## A methodological correction: dropped the baseline normalization

The first version of this analysis normalized every country's DTP3 series to its own 1991-1993 average (the same convention used for GDP in `code/02` and the rejected `hc` extension in `code/07`). That convention makes sense for GDP, which has no common cross-country scale. It does not make sense for DTP3, which is already a percentage on a common 0-100 scale. Worse, normalizing a *bounded* percentage by its own baseline is distorting: a country starting near 90% coverage has almost no room to rise above 1.0 (ceiling effect), while a low-baseline country has enormous room to swing far above 1.0 from a modest percentage-point gain. This is plausibly why the normalized version's synthetic control put 39% of its weight on Somalia (1991-1993 baseline ~21%, among the lowest in the pool) — not because Somalia was a substantively good match, but because the normalization mechanically inflated how much a low-baseline country's later gains could move the fit.

**Dropping normalization and using raw DTP3 percentage-point levels fixes this at the source: Somalia gets 0% weight in the re-fit, without needing a post-hoc exclusion.** `code/13`'s Somalia-exclusion robustness check (previously necessary) is now redundant — it produces results identical to the main fit, because the main fit no longer selects Somalia in the first place. Kept in the repo for the record, not because it's still doing independent work.

## Main result (raw percentage points)

- Donor weights: Swaziland (SWZ) 58%, Republic of the Congo (COG) 21%, Seychelles (SYC) 21% — three donors, nothing on Somalia. (`results/immunization-extension-weights.csv`)
- Pre-treatment RMSPE: 7.56 percentage points — a tight fit on a 0-100 scale.
- 1994 gap: **-64.2 percentage points**, matching the raw 83%→23% crash.
- Average post-treatment gap: **+4.5 percentage points** — positive. Rwanda's actual coverage runs slightly *above* its synthetic counterfactual on average after 1994, not below.
- The path (`figures/immunization-extension-path.png`) shows a tight pre-treatment fit, a sharp one-year collapse, fast recovery, and Rwanda's actual coverage **overtaking** its synthetic counterfactual by the mid-2000s (consistent with Rwanda's well-documented post-genocide health-system investment pushing coverage to near-universal ~97% by the late 2000s, while the donor-pool-based synthetic stays around 85-90%).

This is a materially cleaner and more defensible result than the normalized version, which showed an artificial-looking "persistent unclosed gap" driven substantially by Somalia's mechanically inflated influence.

## Placebo result

**Rwanda's rank: 10 of 21 (p = 0.476).** Improved from the normalized version's 14/21 (p = 0.667), though still not conventionally significant — Rwanda sits almost exactly at the median of the placebo distribution, not toward either tail. Still does not support a strong standalone causal claim from the placebo test alone, consistent with the GDP section's own honest full-pool result (p = 0.775) — but the raw path, especially the overtake after 2000, is a more striking and more defensible descriptive finding than the normalized version produced.

## Files

`results/immunization-extension-path.csv`, `results/immunization-extension-weights.csv`, `results/immunization-extension-placebo.csv`, `figures/immunization-extension-path.png`, `figures/immunization-extension-gaps.png` — current (un-normalized) main result. `results/immunization-no-somalia-*.csv`, `figures/immunization-no-somalia-path.png` — now-redundant Somalia-exclusion check, kept for the record.
