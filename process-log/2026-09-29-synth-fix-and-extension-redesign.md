# Synth optimizer fix, full pipeline re-run, and extension redesign — week of 26 September 2026

## Objective

Diagnose and fix a numerical crash/instability in the `Synth` package's
`genoud` optimizer that was corrupting results across the pipeline, then
resolve the open question of whether PWT's `hc` index is a defensible
extension outcome at all.

## Work completed

- Traced a `genoud`/`ipop` crash to its actual root cause by reading
  `Synth`'s source directly: `kernlab::ipop` (the package's default inner
  quadratic-program solver) is numerically unreliable near sparse
  donor-weight solutions, and does not only fail loudly — it can silently
  return a markedly worse donor-weight vector for a given predictor
  weighting with no error at all. Verified this empirically (same
  predictor weighting, `ipop`'s weights scored 8x worse than an
  alternative solver's weights for the identical input).
- Fixed it by substituting `quadprog::solve.QP` for `ipop` throughout,
  while keeping the method's actual optimization structure unchanged.
  Verified the replacement is faithful to the documented method by
  reading `Synth::synth()`'s help documentation and the package's
  reference paper (Abadie, Diamond & Hainmueller 2011, *Journal of
  Statistical Software* 42(13)) directly, not by assumption — confirmed
  the package's own documented algorithm (two starting points for the
  predictor-weight search, each locally refined, best kept; a third
  globally-searched candidate added when `genoud` is requested) and found
  one further fidelity bug in an earlier attempt at this fix (genoud's
  raw output was being used without the local refinement step the real
  algorithm always applies), which was corrected.
- Re-ran the entire pipeline with the fix. The core GDP path replication
  is materially unchanged (1994 gap -0.555, close to the published -0.58).
  The full 39-country placebo test — the headline inference result — moved
  to a weaker, more rigorous number: rank 31 of 40 (p = 0.775), down from
  an earlier, less rigorously optimized run's rank 21 of 40 (p = 0.53).
  More rigor produced a less favorable result, not a more favorable one.
- Confirmed PWT's `hc` index cannot support the human-capital extension at
  any frequency: it is a linear interpolation of Barro-Lee's five-year
  schooling data (confirmed against PWT's own methodology documentation,
  not just this project's own data audit), and restricting the analysis
  to `hc`'s true five-year measurement points does not rescue it — it
  trades one artifact (fake annual resolution) for another (too few real
  predictors relative to the donor pool, a well-known synthetic-control
  failure mode).
- Surveyed replacement outcome variables. Rejected fertility rate and
  infant mortality rate (same underlying problem as `hc`: UN IGME's
  published series are smoothed between sparse DHS survey waves, and
  Rwanda's own DHS survey gap, 1992 to 2000, brackets the genocide
  exactly) and government education/health expenditure (worse panel gaps
  than the already-rejected WDI school enrollment data, and a weaker
  thematic fit regardless). Confirmed immunization coverage (WHO/UNICEF
  WUENIC, DTP3) as a viable replacement by downloading and checking the
  actual data directly: Rwanda's series is complete 1981-2011 with a real
  one-year crisis signature, not an interpolated line, and a majority of
  the Sub-Saharan African donor pool has adequate coverage.
- Reframed the extension's research question accordingly: immunization
  coverage measures public-health service-delivery/state-capacity
  recovery, not human-capital stock the way `hc` was meant to. The paper
  states this distinction explicitly rather than treating the two as
  interchangeable.
- Drafted the replication and background sections of the paper.

## Generative-AI use and verification

Claude (Anthropic) was used extensively this week for code debugging,
literature/data research, and drafting prose. Verification approach:
every numerical claim above was checked against this repo's own
`results/*.csv`/`.md` output files, not taken on faith from AI-generated
summaries; the `Synth` fix was independently verified by reading the
package's actual R source and its reference paper directly rather than
accepting a first-pass explanation; data-availability claims for
immunization coverage were verified by downloading the underlying WHO/
UNICEF data and checking Rwanda's and the donor pool's actual year-by-
year coverage directly, not by trusting a summarized research pass.
Drafted prose was reviewed against this project's own verified facts
before being treated as usable.

## Decision

- Report the full 39-country placebo result (p = 0.775) as the headline
  inference finding, not the smaller 9-country pool's more favorable
  number (p = 0.30) — the properly-sized donor pool is the honest test.
- Drop PWT `hc` as the extension outcome. Replace with immunization
  coverage, reframed as a public-health/state-capacity recovery question
  rather than a human-capital-stock claim.

## Open items

- The immunization-coverage synthetic control and placebo test
  themselves are not yet built — feasibility is confirmed, the actual
  estimation is not yet run.
- Raw (non-interpolated) DHS mortality data was located and is usable as
  descriptive corroboration only, not yet incorporated.

## Next actions

1. Build the immunization-coverage synthetic control and placebo test.
2. Draft the extension section of the paper once those results exist.
