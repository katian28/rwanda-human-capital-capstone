# Capstone Project Brief — Week 3

Versioned copy of the content submitted via the [Project Brief Cover Sheet](https://mnrva.link/cp-project-brief-cover-sheet) template. Fields marked `[YOU WRITE]` are personal/reflective per the handbook's own guidance and were intentionally left for the student, not drafted by AI.

## Cover sheet

**Name:** Gwaneza Katia Nkurunziza

**Capstone Title:** Did Rwanda's Human Capital Recover Like Its GDP? A Synthetic-Control Replication and Extension of Hodler (2018)

**Academic Abstract** (~190 words):

Hodler (2018) uses a synthetic-control design to estimate that Rwanda's GDP fell by half after the 1994 genocide and took roughly seventeen years to recover. This capstone independently reconstructs that estimate and extends the design to ask whether Rwanda's human capital recovered along a similar path. Using PWT 8.0, the reconstructed GDP path matches Hodler's published benchmarks closely (pre-treatment RMSPE within 0.2% of the published value), and an independently re-estimated donor pool — fit without reference to Hodler's published weights — confirms the 1994 gap despite substantial reshuffling in donor composition. Placebo tests complicate this: at the correct, full Sub-Saharan Africa donor-pool size, Rwanda's post/pre RMSPE ratio ranks 20th of 40 units (p=0.50), indistinguishable from the median country, rather than the more favorable rank obtained from a restricted 9-country pool. The human-capital extension (PWT 8.0 `hc`) shows no comparable shock, with weak but non-trivial placebo evidence (p=0.18) that this null result is itself unusual. The project treats this combination — a replicated path with inconclusive statistical inference — as a substantive finding about the limits of small-donor-pool synthetic control, not a shortfall to be minimized.

**Advisor Name:** `[YOU WRITE]`

**Note to advisor:** `[YOU WRITE — how you're feeling, what you're excited/concerned about, what feedback you want]`

**Three Confirmations:** `[YOU WRITE — initial each after actually doing them: read the handbook through the first committee meeting section; updated your capstone info sheet; understand your group's systems/processes]`

### Links to working files

| Field | Value |
|---|---|
| Main folder(s) | Same as GitHub repo |
| Main writeup | https://docs.google.com/document/d/10uasprh2DbkR8D3T-WnNQ8LxMf14WwPxDb9RohplsvI/edit |
| Slide Deck | Not started |
| GitHub | https://github.com/diamond-minerva-capstone-2026-27/capstone-2026f-katian28 |
| HC & LO plans | https://docs.google.com/spreadsheets/d/1IcCLJEpCi9l9m042oFADtnfnSfDcS8bkfaM0KWoi8FU/edit (HCs), https://docs.google.com/spreadsheets/d/11V9aZ_VWRKdJXTt4ZXjckxUiO05LV6g-H5MFcrASuF8/edit (LOs) — rows to paste into the official [HC/LO tracking template](https://docs.google.com/spreadsheets/d/1L3pUE3shHDAtweDdz1Ex8-ahqeBHi5wJ10H6Ec7raD8/edit) |
| Planning & progress | `PLAN.md` / `PROGRESS.md` in this repo |
| Other | `process-log/` directory in this repo |

**Faculty committee (4-10):** `[YOU WRITE — consult the faculty expertise sheet]`

**Interdisciplinary minor:** `[YOU WRITE, if applicable]`

## 1-Page Summary

This capstone replicates and extends Hodler's (2018) synthetic-control study of Rwanda's post-genocide GDP recovery. The specific focus is twofold: independently verifying the published GDP result, and testing whether Rwanda's human capital recovered on a comparable trajectory using the same method. The approach is a reproducible R pipeline (`code/01-06`) covering replication, independent weight re-estimation, placebo-based inference at two donor-pool sizes, a human-capital extension, and descriptive robustness checks. The work product is an academic paper. Good success looks like: a GDP replication within a declared tolerance of published benchmarks (`#qualitydeliverables`), placebo-based inference reported honestly even when unfavorable (`#outcomeanalysis`), documented pivots when data proved infeasible (`#navigation`), and a paper that separates core findings from exploratory dead ends (`#curation`).

## Short summary of completed work

Reconstructed Hodler's published GDP path from PWT 8.0 within 0.17-0.3% of the reported benchmarks, and identified an unresolved discrepancy between the manuscript's stated outcome variable and the one that actually reproduces it. Independently re-estimated synthetic-control donor weights without reference to the published values, confirming the 1994 gap. Ran in-space and in-time placebo tests at two donor-pool sizes; the honest full-pool result (p=0.50) is reported as the headline rather than a smaller, more favorable pool (p=0.30). Built and validated a reproducible human-capital extension (PWT 8.0 `hc`) with its own placebo test. Added descriptive robustness checks (Barro-Lee, WDI enrollment) and traced the WDI data gap to genuine post-genocide administrative collapse via Rwanda's own Ministry of Education records, not just an international-database artifact. All code, results, and figures are committed and reproducible from the repo.

## General plans for #navigation

Three pivots documented so far, each with its trigger:

1. Switched the extension outcome from WDI enrollment to PWT `hc` after finding the enrollment data fails a balanced-panel screen for exactly the shock window (1994-1998 missing for Rwanda).
2. Expanded the placebo donor pool from 9 to 39 countries after the smaller pool's result (p=0.30) looked more favorable than a properly-sized comparison group supports (p=0.50).
3. Rebuilt a prior session's unreviewed human-capital extension numbers through reproducible code after finding they weren't backed by this repo's pipeline.

`[YOU WRITE — resource identification, meeting prep, how you're working with your advisor: the handbook wants this in your own words]`

## Specific plan for scheduling capstone time

`[YOU WRITE — 12 hrs/week average; how you'll track it (calendar blocks, co-working sessions, time-tracking app)]`

## HC and LO Plans

Filled copies matching the official [HC/LO tracking template](https://docs.google.com/spreadsheets/d/1L3pUE3shHDAtweDdz1Ex8-ahqeBHi5wJ10H6Ec7raD8/edit) columns exactly, ready to paste into that template:
- [HC Tracker](https://docs.google.com/spreadsheets/d/1IcCLJEpCi9l9m042oFADtnfnSfDcS8bkfaM0KWoi8FU/edit) — 18 HCs
- [LO Tracker](https://docs.google.com/spreadsheets/d/11V9aZ_VWRKdJXTt4ZXjckxUiO05LV6g-H5MFcrASuF8/edit) — 4 Capstone LOs + 6 CS major LOs

Narrative version (same content, prose form): https://docs.google.com/document/d/12GQbrnLZ7dipJB0Ot8iyGm3f45evP6PmwhL4JahwOYA/edit

## Anything else advisor told you to include

`[YOU WRITE, if applicable]`
