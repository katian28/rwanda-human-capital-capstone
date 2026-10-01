# Immunization coverage extension: results

**Run date:** 1 October 2026

Public-health service-delivery recovery extension (`code/12_immunization_extension.R`), DTP3 coverage, 20-country Sub-Saharan Africa donor pool with complete 1981-2011 data. See `docs/data-availability.md` for why this replaced `hc` as the extension outcome.

## Main result

- Pre-treatment RMSPE: 0.126 (looser than the GDP fit's 0.0555 — Rwanda's own 1981-1993 DTP3 trajectory is volatile, not a code issue; see Caveats).
- 1994 gap: **-0.832** — a sharp, large, one-year collapse, consistent with the raw coverage crash (83% in 1993 to 23% in 1994).
- The gap closes quickly at first — back near zero by 1996-1997 — but then opens again and stays in the -0.3 to -0.5 range through 2011, never fully closing. This is a different recovery shape than GDP's (which overshoots the synthetic by the mid-2000s): an acute crisis that resolved fast, followed by a persistent, un-closed gap in the pace of improvement relative to the donor pool.

## Placebo result

**Rwanda's rank: 14 of 21 (p = 0.667).** Not statistically distinguishable from ordinary cross-country placebo variation — comparable in spirit to the GDP full-pool result (rank 31 of 40, p = 0.775): the honest test does not support a strong causal claim, even though the raw path shows a real and large deviation.

## Robustness check: excluding Somalia (`code/13_immunization_no_somalia_check.R`)

The main fit put 39% of the synthetic control's weight on Somalia (`results/immunization-extension-weights.csv`), by far the largest single weight, and Somalia's own 1991-1993 baseline DTP3 coverage was unusually low (~21%) and roughly doubled by 2009-2011 for reasons entirely about its own post-1991 civil war and partial recovery — unrelated to Rwanda. Re-fit the entire pipeline (main fit and full placebo loop) with Somalia removed from the donor pool entirely, not just filtered from the results:

| | With Somalia | Without Somalia |
|---|---|---|
| Pre-treatment RMSPE | 0.126 | 0.106 |
| 1994 gap | -0.832 | -0.826 |
| Average post-treatment gap | -0.381 | **-0.016** |
| 2011 gap | (strongly negative) | **+0.039** |
| Placebo rank | 14 of 21 (p = 0.667) | 16 of 20 (p = 0.800) |

**This resolves the caveat, and the resolution matters for how the extension should be written up.** The acute 1994 collapse is robust either way (-0.832 vs. -0.826, essentially identical) — that part of the finding does not depend on Somalia. But the "persistent, unclosed post-2000 gap" described above was substantially a Somalia artifact: with it excluded, the average post-treatment gap is essentially zero and the 2011 endpoint gap is slightly *positive* — Rwanda's immunization coverage tracks its synthetic counterfactual closely by the end of the window, not a lagging recovery. See `figures/immunization-no-somalia-path.png` for the much cleaner picture (tight pre-fit, sharp 1994 drop, convergence by the 2000s).

**The honest story to write up:** a severe, acute, one-year collapse in 1994 that recovers within a few years and converges fully with the counterfactual by 2011 — not a sustained lag. The placebo test is weak either way (p = 0.667 / p = 0.800) and gets weaker without Somalia, which makes sense: a cleaner, more fully-recovered path gives Rwanda a smaller post/pre ratio, so it looks even less unusual next to other placebo countries. Report this as a limitation honestly, the same way the GDP section reports its own weak placebo result as the headline rather than hiding it.

## Files

`results/immunization-extension-path.csv`, `results/immunization-extension-weights.csv`, `results/immunization-extension-placebo.csv`, `figures/immunization-extension-path.png`, `figures/immunization-extension-gaps.png` (main fit, Somalia included); `results/immunization-no-somalia-path.csv`, `results/immunization-no-somalia-weights.csv`, `results/immunization-no-somalia-placebo.csv`, `figures/immunization-no-somalia-path.png` (robustness check, Somalia excluded).
