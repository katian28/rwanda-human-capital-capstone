# Rwanda's Human Capital Recovery After the 1994 Genocide

This repository contains the reproducible research workflow for a Minerva University causal inference capstone. The project asks whether Rwanda's human capital recovered to the trajectory it might have followed without the 1994 genocide, and how that recovery compares with the GDP recovery estimated by Hodler (2018).

## Planned contribution

The project has two stages:

1. Replicate Hodler's synthetic-control estimate of Rwanda's post-genocide GDP recovery.
2. Extend the design to a human-capital outcome, provisionally gross secondary-school enrollment, with additional outcomes used for robustness when the data permit.

The intended audience includes researchers and practitioners in development economics, education policy, post-conflict reconstruction, and impact evaluation.

## Current status

The project is in its initial feasibility and replication stage. The primary outcome, donor pool, specification, and robustness plan remain subject to data validation and advisor feedback.

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
