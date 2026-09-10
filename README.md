# Rwanda's Human Capital Recovery After the 1994 Genocide

This repository contains the reproducible research workflow for a Minerva University causal inference capstone. The project asks whether Rwanda's human capital recovered to the trajectory it might have followed without the 1994 genocide, and how that recovery compares with the GDP recovery estimated by Hodler (2018).

## Planned contribution

The project has two stages:

1. Replicate Hodler's synthetic-control estimate of Rwanda's post-genocide GDP recovery.
2. Extend the design to human capital. The current recommendation is PWT 8.0 `hc` as the technically feasible primary outcome, with Barro–Lee attainment and post-1999 WDI/UIS enrollment as supporting analyses.

The intended audience includes researchers and practitioners in development economics, education policy, post-conflict reconstruction, and impact evaluation.

## Current status

**Current verdict (9 September 2026): proceed with a close GDP replication and redesign the extension.** The exact PWT releases are available, but no author code or assembled replication package has been located. Current WDI secondary enrollment fails the conventional balanced-panel screen; PWT 8.0 human capital has complete annual coverage for Rwanda and 27 eligible donors.

The first replication checkpoint is complete. Applying the published donor weights to PWT 8.0 `rgdpe` reproduces the headline 1994 gap, pre-treatment RMSPE, and 2011 closure. The manuscript names `rgdpo`, but that variable does not reproduce the published path. See the [validation memo](results/replication-validation.md) and [reconstruction figure](figures/published-weight-gdp-replication.png).

## Project knowledge base

This repository is the canonical record for the project. Research decisions, source links, feasibility findings, advisor-approved changes, and weekly progress should be documented here before they are treated as settled.

- [Replication feasibility audit](docs/replication-feasibility.md)
- [Human-capital data availability audit](docs/data-availability.md)
- [Full feasibility report and decision memo](docs/feasibility-report.md)
- [Source register](docs/source-register.md)
- [Knowledge-base standards and navigation](docs/README.md)
- [Weekly process log](process-log/)
- [Reading notes](references/reading-notes.md)

## Priority for 9–13 September 2026

This week's evidence-backed decisions are:

1. **Original finding:** a close replication with original PWT vintages is feasible; exact numerical replication remains conditional on remaining historical predictors and undocumented preprocessing.
2. **Extension:** retain the question, but do not use current WDI secondary enrollment as the primary outcome in conventional `Synth`.

The dated execution plan and go/no-go checkpoint are in the [decision memo](docs/feasibility-report.md).

## Repository structure

```text
data/
  raw/          Original source data; excluded from Git by default
  processed/    Analysis-ready data; excluded from Git by default
code/           Ordered scripts for the reproducible workflow
figures/        Generated figures; excluded from Git by default
results/        Generated model outputs; excluded from Git by default
writing/        Drafts and submission materials
references/     Reading notes and citation metadata
process-log/    Weekly progress, decisions, feedback, and navigation evidence
environment/    Reproduction and dependency instructions
```

## Planned workflow

- [ ] Confirm the scope and primary outcome with the capstone advisor.
- [ ] Audit candidate datasets for temporal coverage, missingness, and comparability.
- [ ] Document Hodler's original data, donor pool, predictors, and specification.
- [ ] Reproduce the main GDP result.
- [ ] Pre-specify the human-capital extension and sensitivity checks.
- [ ] Run placebo tests and RMSPE-based inference.
- [ ] Produce a reproducible research paper, codebase, figures, and data documentation.

## Reproducibility and data policy

- Raw data will not be edited manually.
- Each script will have one clear purpose and will run in numerical order.
- Important analytical decisions and changes will be recorded in the process log.
- Dataset licenses will be checked before any data are redistributed.
- Credentials, personal information, restricted data, and private feedback must never be committed.

## Key reference

Hodler, R. (2018). The Economic Effects of Genocide: Evidence from Rwanda. *Journal of African Economies*. https://doi.org/10.1093/jae/ejy008

## Contact and academic context

This is an evolving student research project. Results should not be treated as established findings until the analysis and review process are complete.
