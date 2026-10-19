# Progress notes — Gwaneza Katia Nkurunziza

Add a new entry before each meeting. Newest at the top. Three lines is enough.

## 2026-10-19
- **Done:** Added PWT human capital as a 7th GDP predictor, confirmed directly against the manuscript PDF (an earlier version had missed it, no documented reason) — narrowed the full-pool donor list 37→26 and improved the placebo rank 18/38→9/27. Reading further into the manuscript then surfaced a bigger finding: this project's full-pool placebo test was never actually a reconstruction of Hodler's own inference — he uses a 22-country pool with year-by-year significance (a separate p-value for each post-treatment year), not a 26-country whole-period test. Built committee-meeting slides and prepped for the first committee meeting.
- **Next:** Reconstruct Hodler's exact 22-country placebo pool and implement year-specific inference, reported alongside (not replacing) the existing full-pool test; repair code/14_predictor_assembly_check.R, which still reflects the pre-`hc` predictor set.
- **Blocked:** None currently.

## 2026-10-12
- **Done:** Fixed a replication-fidelity problem (Liberia, one of Hodler's own 9 donors, had been dropped because WDI CPI inflation has zero coverage for it pre-2002) by switching to WDI's GDP-deflator inflation series across code/02-06; full-pool placebo improved from 20/30 (p=0.667) to 18/38 (p=0.474). Rebuilt the immunization extension's predictors (added MCV1, UCDP conflict, GDP per capita; code/12), which also resolved Somalia's old weight-dominance problem at the source — placebo rank moved from 10/21 (p=0.476) to 12/19 (p=0.632), reported honestly even though weaker. Removed code/13 (now-redundant Somalia-exclusion check). Redrafted all 7 writing/drafts sections against the updated facts files.
- **Next:** Review the redrafted sections end to end; decide whether to build an in-time placebo for the extension (the GDP side has one, the extension doesn't); update PLAN.md off its original human-capital-extension template before the first committee meeting.
- **Blocked:** None currently.

## 2026-10-01
- **Done:** Fixed a real numerical bug in how `Synth`'s genoud optimizer was being used (silently returned suboptimal donor weights near sparse solutions); re-ran the full pipeline with a verified-faithful reimplementation of `synth()`'s actual documented algorithm. Headline full-pool GDP placebo moved to its honest, final value: rank 31/40 (p=0.775). Diagnosed `hc` as unusable at any frequency (fabricated annual resolution, confirmed by PWT's own methodology docs); surveyed and rejected fertility/infant mortality and government spending as replacements; confirmed immunization coverage (DTP3) passes the balanced-panel screen and reframed the extension around public-health service-delivery recovery. Drafted the replication and background sections of the paper.
- **Next:** Build the immunization-coverage synthetic control and placebo test (mirrors code/07's structure); draft the extension section once those results exist.
- **Blocked:** None currently.

## 2026-09-23
- **Done:** Independently re-estimated GDP donor weights and re-ran all placebo tests (9-country, full 39-country, in-time) using the actual `Synth` package (Abadie, Diamond & Hainmueller), not just a hand-rolled fit; GDP placebo confirmed weak (p=0.53). Tested Hodler's own placebo-exclusion rule — does not change the GDP result. Rebuilt the human-capital extension with `Synth`; its placebo result improved to p=0.071, clearing the 10% threshold. Built the human-capital extension, Barro-Lee/WDI robustness checks, and traced the WDI 1994-1998 gap to genuine administrative collapse via MINEDUC records. Assembled the Week 3 Project Brief, HC/LO tracker, and committee list.
- **Next:** In-time placebo for the human-capital extension via `Synth`; full predictor-set re-estimation (PWT 7.1, WDI inflation, Polity IV, Freedom House, UCDP) as a robustness check; finalize committee and advisor sign-off on framing (replicated path vs. weak GDP significance).
- **Blocked:** None currently — `rgdpe`/`rgdpo` discrepancy remains documented but unresolved with the author; not blocking further work.

## 2026-09-14
- **Done:** Replication checkpoint complete—reconstructed published GDP result to within 0.3% using PWT 8.0 and reported donor weights. Data audit finished. Merged personal repo into private capstone repo. Identified rgdpe/rgdpo variable-label discrepancy.
- **Next:** Investigate variable-label issue; re-estimate synthetic-control weights independently; run in-space placebo test.
- **Blocked:** Author code not located; rgdpe/rgdpo issue requires investigation before calling replication "complete" (but does not block further progress).
