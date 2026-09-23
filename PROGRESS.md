# Progress notes — Gwaneza Katia Nkurunziza

Add a new entry before each meeting. Newest at the top. Three lines is enough.

## 2026-09-23
- **Done:** Independently re-estimated GDP donor weights and re-ran all placebo tests (9-country, full 39-country, in-time) using the actual `Synth` package (Abadie, Diamond & Hainmueller), not just a hand-rolled fit; GDP placebo confirmed weak (p=0.53). Tested Hodler's own placebo-exclusion rule — does not change the GDP result. Rebuilt the human-capital extension with `Synth`; its placebo result improved to p=0.071, clearing the 10% threshold. Built the human-capital extension, Barro-Lee/WDI robustness checks, and traced the WDI 1994-1998 gap to genuine administrative collapse via MINEDUC records. Assembled the Week 3 Project Brief, HC/LO tracker, and committee list.
- **Next:** In-time placebo for the human-capital extension via `Synth`; full predictor-set re-estimation (PWT 7.1, WDI inflation, Polity IV, Freedom House, UCDP) as a robustness check; finalize committee and advisor sign-off on framing (replicated path vs. weak GDP significance).
- **Blocked:** None currently — `rgdpe`/`rgdpo` discrepancy remains documented but unresolved with the author; not blocking further work.

## 2026-09-14
- **Done:** Replication checkpoint complete—reconstructed published GDP result to within 0.3% using PWT 8.0 and reported donor weights. Data audit finished. Merged personal repo into private capstone repo. Identified rgdpe/rgdpo variable-label discrepancy.
- **Next:** Investigate variable-label issue; re-estimate synthetic-control weights independently; run in-space placebo test.
- **Blocked:** Author code not located; rgdpe/rgdpo issue requires investigation before calling replication "complete" (but does not block further progress).
