# Source register

**Access date for all entries:** 9 September 2026

## Article and author materials

- Journal record: https://doi.org/10.1093/jae/ejy008
- Public manuscript: https://purehost.bath.ac.uk/ws/portalfiles/portal/118534302/economic_effects_political_violence_rwanda.pdf
- Author research page searched for code/data: https://sites.google.com/view/rolandhodler/research
- RePEc article record searched for related files: https://ideas.repec.org/a/oup/jafrec/v28y2019i1p1-17..html

## Replication inputs

- PWT 8.0: https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt8.0?lang=en — GDP and human capital; CC BY 4.0 shown by publisher.
- PWT 7.1: https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt-7.1?lang=en — investment and openness; record exact file terms and checksum.
- World Bank API: https://datahelpdesk.worldbank.org/knowledgebase/articles/889392 — inflation and enrollment retrieval.
- WDI archives: https://datatopics.worldbank.org/world-development-indicators/wdi-archives.html — historical vintages.
- UNESCO UIS bulk data: https://databrowser.uis.unesco.org/resources/bulk — alternative official education-data extraction.
- UCDP: https://ucdp.uu.se/downloads/ — current and historical conflict data; CC BY 4.0 for current datasets.
- Freedom House: https://freedomhouse.org/report/freedom-world — political rights; document access/reuse conditions for the selected file.
- Polity IV legacy project: https://www.systemicpeace.org/polity/polity4.htm — identify and archive the matching historical release.
- Barro–Lee: https://barrolee.github.io/BarroLeeDataSet/ — five-year educational-attainment data and methodology. Full citation: Barro, R.J. & Lee, J-W. (2013), "A new data set of educational attainment in the world, 1950-2010," *Journal of Development Economics* 104: 184-198, https://doi.org/10.1016/j.jdeveco.2012.10.001 (paywalled; free NBER working-paper version: https://www.nber.org/papers/w15902). This is the actual empirical input behind PWT's `hc` index (below), not an independent data source.
- Psacharopoulos, G. (1994), "Returns to investment in education: A global update," *World Development* 22(9): 1325-1343, https://www.sciencedirect.com/science/article/abs/pii/0305750X94900078 (paywalled) — source of the assumed Mincerian return rates PWT's `hc` is built on.
- Caselli, F. (2005), "Accounting for cross-country income differences," in *Handbook of Economic Growth* Vol. 1A: 679-741 — free full text at https://personal.lse.ac.uk/casellif/papers/handbook.pdf (also as NBER working paper: https://www.nber.org/system/files/working_papers/w10828/w10828.pdf). Implements Psacharopoulos's return rates as the piecewise-linear `φ(s)` formula PWT's `hc` methodology cites directly.
- PWT `hc` construction methodology: https://www.rug.nl/ggdc/docs/human_capital_in_pwt_90.pdf — checked 28 September 2026. Confirms `hc` is built from (1) Barro-Lee average years of schooling `s` and (2) the assumed (not per-country-estimated) piecewise-linear Mincerian return schedule above: 13.4% per year for the first 4 years of schooling, 10.1% for years 5-8, 6.8% beyond that. Critically, the document states directly: **"Regardless of the chosen series, we interpolate linearly between observations"** — i.e. PWT's own methodology note confirms, in its own words, exactly the mechanical linear interpolation between Barro-Lee's five-year points that `code/09_hc_interpolation_check.R` found empirically (see `docs/data-availability.md`). This is independent, authoritative confirmation, not just this project's own reverse-engineering.
- Bridgeland, J., Wulsin, S., & McNaught, M. (2009). *Rebuilding Rwanda: From Genocide to Prosperity Through Education*. Civic Enterprises, LLC, with Hudson Institute. https://files.eric.ed.gov/fulltext/ED509757.pdf — Appendix E reproduces Rwanda Ministry of Education (MINEDUC) secondary-education statistics; the table itself starts in 1997, and the report states secondary schools did not reopen until 20 October 1994. Checked 20 September 2026 to see whether Rwandan government administrative data could fill the WDI 1994–1998 gap; it cannot — MINEDUC's own compiled series has the same gap.
- WHO/UNICEF WUENIC (Estimates of National Immunization Coverage): methodology notes at https://cdn.who.int/media/docs/default-source/immunization/immunization-coverage/wuenic_notes.pdf (confirms 1980 start, and that gap-filling for isolated missing country/year cells is targeted interpolation, not a wholesale annual-series fabrication); portal at https://immunizationdata.who.int/. Bulk panel data (long-format CSV, redistributed by Our World in Data, verified to match the WHO source directly): https://ourworldindata.org/grapher/share-of-children-immunized-dtp3.csv (DTP3) and https://ourworldindata.org/grapher/share-of-children-vaccinated-against-measles.csv (MCV1). Checked 29 September 2026 as a candidate replacement extension outcome after `hc` and WDI enrollment both failed the balanced-panel screen — passes: Rwanda's DTP3 series is complete 1981-2011 with no missing years, including a real (not interpolated) crisis signature in 1994 (83% in 1993 → 23% in 1994 → 83% in 1995), and 38 of 43 Sub-Saharan African candidate donors have complete gap-free coverage starting 1990 or earlier. See `results/immunization-feasibility-check.md` and `code/11_immunization_feasibility_check.R`.

## Search conclusion

No author-supplied code or assembled replication package was located as of 9 September 2026. This is a dated search finding, not proof that no package exists. The next step is a concise author request while independent reconstruction continues.
