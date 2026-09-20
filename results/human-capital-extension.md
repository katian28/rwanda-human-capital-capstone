# Human-capital extension (PWT 8.0 `hc`)

**Run date:** 19 September 2026

## Donor pool

Same Sub-Saharan Africa construction as `code/04_placebo_full_pool.R` (43 candidates), screened for complete `hc` coverage 1970-2011 instead of `rgdpe`: 27 eligible donors.
Dropped for incomplete `hc` coverage: AGO, BFA, CPV, TCD, COM, GNQ, ERI, ETH, GIN, GNB, MDG, NGA, STP, SYC, SOM, SSD.

## Main result

Pre-treatment RMSPE: 0.0001.
Post-treatment (1994-2011) average gap: 0.057. Largest-magnitude gap: 0.083 in 2005.
Direction: Rwanda's human-capital index sits ABOVE its synthetic counterfactual after 1994 -- no genocide-era shock visible in this index..

**Donor weights (>1%):**

| Donor | Weight |
|-------|--------|
| ZMB | 0.204 |
| MLI | 0.180 |
| CIV | 0.172 |
| NER | 0.171 |
| MOZ | 0.119 |
| ZAF | 0.112 |
| GMB | 0.042 |

## In-space placebo

Rwanda's rank: 5 of 28 (p = 0.179).
This does NOT clear the conventional 10% rank-based placebo threshold -- consistent with the main result showing no clear post-1994 shock in this index.

## Interpretation

The PWT human-capital index is a smoothed, constructed measure built from schooling and assumed returns (see `docs/data-availability.md`). A flat or positive post-1994 gap here is consistent with two different stories that this design cannot distinguish: (a) Rwanda's human capital did not suffer a comparable shock to its GDP, or (b) the index is too smoothed/slow-moving to register a shock of this kind. This ambiguity should be stated as a limitation, not resolved by assumption.

**Supersedes:** the hc numbers a prior session wrote into the paper's Section 4 without access to this repo's code or data pipeline (see doc comment thread, 2026-09-19). Use these numbers instead.
