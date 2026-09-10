# Feasibility week — 9 September 2026

## Objective

Determine by 13 September whether the original GDP findings can be replicated and whether a defensible human-capital outcome is available for Rwanda and an eligible donor pool.

## Work completed

- Established the GitHub repository as the canonical project knowledge base.
- Located a public manuscript and extracted the main outcome, source vintages, donor exclusions, predictor windows, inference rules, published donor weights, and benchmark results.
- Conducted an initial search for author-supplied replication code and assembled data; none was located in the searched sources.
- Confirmed public entry points for current PWT, WDI/UNESCO secondary enrollment, Barro–Lee attainment, UCDP, and Freedom House data.
- Confirmed that the exact PWT 8.0 and 7.1 archives are live.
- Audited PWT 8.0: Rwanda is complete for `rgdpo` and `hc` from 1970–2011; 39 eligible donors are complete for `rgdpo` and 27 for `hc`.
- Audited WDI `SE.SEC.ENRR`: Rwanda is observed in 1971, 1976–1992, and 1999–2011; only Lesotho is complete over Rwanda's continuous pre/post windows.
- Audited Barro–Lee version 3: Rwanda is present at five-year intervals through 2015.
- Recorded a decision memo, source register, and dated execution plan.
- Completed the first GDP replication checkpoint using the exact PWT 8.0 file and published donor weights.
- Reproduced the headline path with `rgdpe`: RMSPE 0.0574, 1994 gap −0.582, and 2011 gap −0.004.
- Found that the manuscript's stated `rgdpo` variable does not reproduce the path, indicating an apparent variable-label inconsistency to investigate.

## Important distinction

The project will distinguish:

- **exact replication** using the original vintages and specification;
- **close replication** reconstructed from original vintages without author code; and
- **modern-data reconstruction** using updated releases.

These labels will not be used interchangeably.

## Decision

- Proceed with an independently reconstructed close GDP replication.
- Redesign the extension: PWT 8.0 `hc` is the lowest-risk primary outcome, subject to advisor approval and careful interpretation.
- Do not use current WDI enrollment as the primary outcome with conventional balanced-panel `Synth`.
- Retain Barro–Lee and post-1999 enrollment as supporting analyses.

## Open risks

- Author code and assembled replication data may not be publicly deposited.
- Current source releases may revise values relative to the paper's inputs.
- Exact Polity IV, WDI inflation, Freedom House, and UCDP vintages and transformations remain to be frozen.
- PWT `hc` is a constructed, smoothed index and may not capture an abrupt shock directly.

## Next actions

1. Freeze source files, versions, licenses, and checksums by 10 September.
2. Reconstruct the GDP path from PWT 8.0 and published donor weights by 11 September.
3. Re-estimate weights and run pre-treatment-only extension diagnostics by 12 September.
4. Freeze the design and final go/no-go decision by 13 September.
