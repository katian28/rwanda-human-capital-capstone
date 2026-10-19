# Project plan — Gwaneza Katia Nkurunziza

## One-paragraph description

Replicate and extend Hodler's (2019) synthetic-control estimate of Rwanda's post-genocide GDP recovery. The project reconstructs the published GDP result from Penn World Table 8.0, independently re-estimates synthetic-control weights using Hodler's own documented predictor set, reproduces placebo-based inference (restricted-pool, full-pool, and in-time), and extends the analysis to immunization coverage (WHO/UNICEF WUENIC DTP3) to assess how quickly basic public-health service delivery recovered after the genocide — a state-capacity question, not a human-capital-stock claim (the originally planned PWT `hc` extension was investigated and rejected; see `docs/paper-facts-extension.md`).

## Milestones

| Milestone | Status | What's observable in this repo |
|---|---|---|
| Replication checkpoint | **Done** | Published-weight GDP reconstruction verified (`rgdpe`, not `rgdpo` — a genuine label discrepancy in Hodler's own manuscript, documented not just resolved); independent weight re-estimation using all seven of Hodler's documented predictors (confirmed directly against the manuscript PDF, including `hc`, which an earlier version had missed), all nine published donors including Liberia |
| Placebo-based inference | **In progress** | Restricted 9-country pool (rank 3/10) and our own full 26-country/27-unit whole-period pool (rank 9/27) are done, via the `Synth` package directly. Confirmed directly against the manuscript that this is *not* a reconstruction of Hodler's own inference: his placebo pool is 22 countries, and his significance test is computed year-by-year, not over the whole post-period at once. Reconstructing his exact pool and year-specific procedure is open work, tracked below |
| Extension outcome selection | **Done** | `hc`, fertility/mortality, and government expenditure investigated and rejected (fabricated or interpolated resolution); immunization coverage (DTP3) adopted, passes the balanced-panel/genuinely-annual screen |
| Extension results | **Done** | Main fit, full external-predictor set (MCV1, UCDP conflict, GDP per capita), 18-country donor pool, in-space and in-time placebos |
| Paper sections drafted | **Done** | All six replication + extension subsections (methodology/results/inference × 2) drafted in `writing/drafts/`, grounded in the current numbers |
| First committee meeting | **Next** | Committee-facing summary prepared; sign-off on framing (replicated path vs. weak GDP/extension placebo significance, reported honestly rather than smoothed over) |
| Hodler-exact pool + year-specific inference | **In progress** | Reconstruct his 22-country placebo pool and year-by-year significance test, report alongside (not instead of) this project's own full-pool whole-period test |
| Full manuscript | **Pending** | Draft sections assembled into one document; limitations section written; final read-through |

## Known risks

- The GDP replication's own full-pool placebo result (rank 9 of 27, p = 0.333) and the extension's (rank 12 of 19, p = 0.632) both fail to clear conventional significance — the path reconstructs in both cases, the placebo-based causal claim does not. This is a finding to present plainly, not a risk to resolve away.
- This project's full-pool placebo test is *not* a reconstruction of Hodler's own inference procedure — confirmed directly against the manuscript. He uses a 22-country placebo pool (not our 26/27) and a year-by-year significance test (not our single whole-period RMSPE ratio). Both are legitimate inference approaches, but conflating them would misrepresent what was actually replicated; report both, clearly labeled, once the reconstruction is done.
- Immunization coverage measures public-health service-delivery capacity, not human capital — the paper must not blur this distinction when discussing implications.
- Author code for Hodler (2019) was never located; this remains a close replication (independently reconstructed, matched to documented specification), not an exact one.
- Donor pools differ in size across the two sections (9/26 for GDP, 18 for immunization) for data-availability reasons specific to each outcome — worth a sentence of explanation if a reader asks why they aren't the same.

## Revisions

- **19 October 2026:** Added PWT human capital (`hc`) as a 7th GDP predictor, confirmed directly against the manuscript PDF as one Hodler actually specifies — an earlier version had missed it with no documented reason. This narrowed the full-pool placebo donor list (37 → 26) and improved the rank (18/38 → 9/27). Separately, reading further into the manuscript confirmed this project's full-pool test was never actually a reconstruction of Hodler's own placebo procedure: his is a 22-country pool with year-by-year significance, not our 26-country whole-period test. Reconstructing his exact design is now tracked as open work rather than conflated with our own robustness check.
- **13 October 2026:** Replaced the human-capital extension framing throughout (rejected; see `docs/paper-facts-extension.md` for the full investigation) with the immunization-coverage/service-delivery extension that replaced it. Switched milestones from the original week-number template to a status-based list reflecting actual completion, since the replication and extension are both substantively further along than the template's Week 15-19 framing assumed. Updated known risks to reflect what is actually still open (significance, construct-validity framing, missing author code, differing donor-pool sizes) rather than issues already resolved (the `rgdpe`/`rgdpo` discrepancy, which is now a documented finding, not an open risk).
