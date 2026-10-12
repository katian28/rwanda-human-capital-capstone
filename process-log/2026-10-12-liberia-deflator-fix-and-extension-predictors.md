# Liberia/GDP-deflator fix and extension predictor rebuild — week of 6 October 2026

## Objective

Fix a replication-fidelity problem flagged on review (Liberia, one of
Hodler's own 9 published donors, had been dropped from this project's
donor pool), and bring the immunization extension's predictor set up to
the same standard as the GDP replication's (external covariates, not
just the outcome's own lags).

## Work completed

- **Diagnosed why Liberia had been dropped.** An earlier version of the
  predictor-assembly work used WDI's standard CPI inflation series
  (`FP.CPI.TOTL.ZG`), which has zero coverage for Liberia before 2002
  (its own 1989-2003 civil wars) — not a parsing gap, a genuine absence.
  This had forced Liberia out of the 9-donor pool, which defeats the
  purpose of a replication: imitating the original paper as closely as
  the data allows, not narrowing its donor set because of an avoidable
  choice of inflation series.
- **Fixed it at the source, not by working around it.** Switched to
  WDI's GDP-deflator inflation series (`NY.GDP.DEFL.KD.ZG`), verified
  directly (not assumed) to have full 1985-1990 coverage for Liberia and
  all 8 other Hodler donors, and far better coverage than CPI across the
  wider ~43-country candidate pool generally (40 of 43 vs. 24 of 43).
  Propagated the fix to all three GDP scripts that use Hodler's full
  predictor set (`code/02`, `03`, `04`) and reran each one.
- **Found a second, unrelated data gap while rebuilding the full-pool
  placebo test (`code/04`):** Penn World Table 8.0 has zero rows at all
  for Somalia — not a window gap, no data for any year, any variable.
  This is a genuine PWT limitation (consistent with Somalia's 1991 state
  collapse making national-accounts estimation impractical), not
  something any inflation-series choice could have fixed, so Somalia is
  excluded from the full-pool candidate list (37 donors, down from an
  attempted 38) separately from the Liberia fix.
- **Results after the fix:** main GDP result (`code/02`) now matches the
  published benchmark more closely than any earlier version — pre-
  treatment RMSPE 0.0421 (published 0.0584), 1994 gap -0.578 (published
  -0.58). The full-pool placebo test (the headline inference result)
  improved substantially: Rwanda's rank moved from 20 of 30 (p = 0.667)
  to 18 of 38 (p = 0.474) — still not conventionally significant, but a
  materially stronger result from using the full, correctly-sourced
  donor pool rather than a shrunken one.
- **Rebuilt the immunization extension's predictor set** (`code/12`) to
  match this standard: added MCV1 (measles) coverage, UCDP conflict, and
  GDP per capita as external special predictors, alongside the existing
  lagged-DTP3-coverage predictors. GDP per capita has zero PWT coverage
  for Somalia and Seychelles, so both drop from that donor pool (20 to
  18) — a side effect that also resolves, at the data-sourcing stage, an
  earlier problem where Somalia's unusually low baseline dominated the
  synthetic control's weights.
- **Result:** the extension's placebo rank moved from 10 of 21
  (p = 0.476) to 12 of 19 (p = 0.632) — weaker, not stronger. Recorded
  this plainly rather than reverting to the simpler specification: the
  predictor rebuild was motivated by specification fidelity, and it
  moving the result in the less favorable direction is itself evidence
  the choice wasn't reverse-engineered from the number.
- **Removed `code/13`** (the Somalia-exclusion robustness check for the
  immunization extension). It had been built for an earlier, different
  donor pool; once Somalia started dropping from `code/12`'s own pool
  automatically, the two scripts converged to testing the same pool, and
  `code/13` had not been rerun against the current predictor
  specification. It was a stale duplicate, not an independent check.
  Recoverable from git history if needed.
- Redrafted both facts files (`docs/paper-facts-replication.md`,
  `docs/paper-facts-extension.md`) and the public `docs/replication-
  summary.md` with the final numbers from all of the above.

## Generative-AI use and verification

Claude Code was used throughout. Every numerical claim in this entry was
checked against actual script output (re-running `code/02` through
`code/06` and `code/12` after each change, reading the resulting CSVs
directly), not accepted from a first-pass description. The Somalia/PWT
and Somalia-Seychelles/PWT-per-capita data gaps were confirmed by
querying the raw downloaded files directly in R, not assumed from a
prior pattern. The predictor-rebuild's effect on both placebo ranks
(replication: improved; extension: worsened) was reported as found, not
adjusted after the fact to favor one direction.

## Decision

- Report GDP-deflator inflation as the predictor going forward for the
  GDP replication's external predictor set; do not revert to CPI even
  though it was the simpler original choice, since it forces dropping a
  real published donor for no good reason.
- Report the extension's weaker placebo result honestly, rather than
  omitting the external predictors to preserve the better-looking
  earlier number.
- Remove `code/13` rather than rerun it, since its premise (an
  independent Somalia-exclusion check) no longer holds once Somalia is
  excluded from the main analysis for an unrelated, earlier-stage reason.

## Open items

- The immunization extension still has no in-time placebo test (the GDP
  replication has one, in `code/03`/`04`); this asymmetry has not been
  resolved.
- `writing/drafts/*.md` is being redrafted against the updated facts
  files this week; not yet reviewed end to end.

## Next actions

1. Finish reviewing the redrafted replication and extension sections.
2. Decide whether to build the extension's in-time placebo before the
   first committee meeting.
3. Update `PLAN.md` off its original template (still names the
   superseded human-capital extension).
