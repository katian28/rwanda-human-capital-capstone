# Capstone feasibility report and decision memo

**Prepared:** 9 September 2026  
**Scope:** replicate Hodler’s Rwanda GDP findings and extend the design to human capital  
**Decision:** **Proceed with a close GDP replication and redesign the extension.**

## Executive verdict

You do not need to abandon the capstone. The core replication is feasible because the exact Penn World Table releases are available, the article documents most of the design, and published donor weights and benchmark estimates make the first reconstruction testable. The absence of located author code means the result should be called a **close replication** unless the independent implementation matches the published values within a declared tolerance.

The extension is feasible only after revision. Current WDI secondary-enrollment data do not support a conventional balanced annual synthetic control: Rwanda has no observations for 1994–1998 and only one eligible donor is complete over Rwanda’s continuous pre/post windows. PWT 8.0 human capital supports an annual balanced panel with 27 eligible donors, though it is a smoothed constructed index. Barro–Lee is available at five-year intervals and is best used as supporting evidence.

## Decision matrix

### Core GDP replication — GO

- Exact PWT 8.0 and 7.1 releases: available.
- Article specification: substantially documented.
- Author code/assembled data: not located as of 9 September 2026.
- Classification: close replication feasible; exact replication conditional.
- Immediate task: reproduce the main GDP path using PWT 8.0 and the paper’s published donor weights before re-estimating weights.

### WDI secondary enrollment with conventional synthetic control — NO-GO as primary

- Rwanda pre-period: 18 observed years, concentrated in 1976–1992 plus 1971.
- Rwanda post-period through 2011: observations begin only in 1999.
- Complete eligible donors for Rwanda’s continuous 1976–1992 and 1999–2011 windows: one.
- Consequence: no credible conventional balanced annual donor pool.
- Permissible role: descriptive post-1999 outcome, or primary outcome only with an advisor-approved missing-data-capable estimator.

### PWT 8.0 human capital — CONDITIONAL GO

- Balanced annual coverage: Rwanda plus 27 eligible donors for 1970–2011.
- Main risk: a constructed, interpolated human-capital stock may smooth the shock and does not directly measure learning.
- Permissible claim: effect on the PWT human-capital index, not direct recovery of skills or educational quality.

### Barro–Lee attainment — GO for robustness only

- Rwanda observations: five-year intervals through 2015.
- Main risk: too few time points to resolve annual recovery; filled/extrapolated values require caution.
- Permissible role: low-frequency long-run corroboration.

## Evidence supporting the decision

Hodler’s [public manuscript](https://purehost.bath.ac.uk/ws/portalfiles/portal/118534302/economic_effects_political_violence_rwanda.pdf) supplies the outcome, treatment date, donor exclusions, predictor families and windows, normalized outcome years, placebo design, RMSPE rule, donor weights, and benchmark results. The [journal record](https://academic.oup.com/jae/article-abstract/28/1/1/5001410) confirms publication details and the headline 58% GDP decline and 17-year recovery. The journal issue displays a generic “Supplementary data” link, but it resolves to the article rather than exposing downloadable files. Targeted searches of the journal, the author’s [research page](https://sites.google.com/view/rolandhodler/research), RePEc, GitHub, and the open web did not locate code or assembled data.

The exact [PWT 8.0 archive](https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt8.0?lang=en) and [PWT 7.1 archive](https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt-7.1?lang=en) remain available. The [World Bank API](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392) makes the enrollment audit reproducible, and historical WDI snapshots are listed in the [WDI archive](https://datatopics.worldbank.org/world-development-indicators/wdi-archives.html). [UNESCO UIS](https://databrowser.uis.unesco.org/resources/bulk) offers official bulk files for an additional vintage check. [UCDP](https://ucdp.uu.se/downloads/) provides current and historical conflict datasets. [Freedom House](https://freedomhouse.org/report/freedom-world) supplies historical political-rights data with access/reuse conditions to document. The [Barro–Lee project](https://barrolee.github.io/BarroLeeDataSet/) supplies downloadable attainment data and methodology.

## Work plan

### 9–10 September: freeze the inputs

1. Record URLs, versions, access dates, licenses, and checksums for every source.
2. Convert the paper’s specification into a machine-readable sheet: variables, transformations, years, exclusions, and inference rules.
3. Ask the author for code and assembled data, but do not make progress contingent on a reply.
4. Ask the advisor to approve PWT `hc` or an explicitly missing-data-capable enrollment estimator.

### 11 September: prove the core reconstruction

1. Normalize PWT 8.0 `rgdpo` exactly as described.
2. Apply the published donor weights without optimization.
3. Compare pre-treatment RMSPE, the 1994 gap, and 2011 closure with the paper.
4. Save the figure, metrics, and deviations in `results/` and the decision in `process-log/`.

### 12 September: re-estimate and audit the extension

1. Assemble the original predictor panel from frozen historical versions.
2. Estimate donor weights and compare them with the published weights.
3. Inspect pre-treatment data and fit only for the selected extension; freeze tuning before viewing post-treatment results.
4. Record excluded donors and reasons before estimation.

### 13 September: go/no-go checkpoint

Proceed if the close replication reproduces the qualitative GDP path and credible pre-treatment fit. Proceed with the extension only if its pre-treatment fit and placebo comparison set are defensible. If PWT `hc` is too indirect and enrollment remains incompatible with the approved estimator, change the extension outcome while retaining the GDP replication.

## Paper structure

1. Motivation: GDP recovery may differ from accumulated human-capital recovery.
2. Replication: independent reconstruction of Hodler’s synthetic-control estimate.
3. Data audit: vintages, missingness, and construct validity.
4. Extension: pre-specified PWT 8.0 human-capital outcome.
5. Robustness: Barro–Lee attainment and descriptive WDI/UIS enrollment from 1999.
6. Inference: in-space and in-time placebos, RMSPE ratios, and donor-rule sensitivity.
7. Limitations: missing author code, revisions, interpolated measures, and inability of enrollment data to identify 1994–1998.

## Final decision rule

Do not change the entire capstone idea now. Change the extension design. Reconsider the whole project only if the published-weight GDP reconstruction fails despite matching PWT 8.0 transformations, or if the course requires exact author-code replication rather than an independent close replication.
