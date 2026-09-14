# Replication feasibility: Hodler (2019)

**Decision:** GO for a close replication; exact numerical replication remains conditional

**Evidence date:** 9 September 2026

**Target article:** Roland Hodler, “The Economic Effects of Genocide: Evidence from Rwanda,” *Journal of African Economies* 28(1), 1–17, DOI: [10.1093/jae/ejy008](https://doi.org/10.1093/jae/ejy008)

## Bottom line

The main GDP result is replicable as a transparent, independently reconstructed **close replication**. The exact PWT releases named in the paper are available, the manuscript provides substantial specification detail, and the published donor weights and headline estimates supply strong validation targets. However, no author-supplied code or assembled replication dataset was located in the journal record, the author’s current research page, RePEc, GitHub, or targeted web searches as of the evidence date. Exact numerical identity therefore cannot be promised until the remaining historical predictor vintages and all preprocessing choices have been matched.

This project must not describe a PWT 10.0 or 11.0 analysis as a replication of the original inputs. The original analysis used PWT 8.0 for GDP and human capital and PWT 7.1 for investment and openness.

## What can be reconstructed now

The [public manuscript](https://purehost.bath.ac.uk/ws/portalfiles/portal/118534302/economic_effects_political_violence_rwanda.pdf) identifies:

- real GDP at chained purchasing-power parities (`rgdpo`) from PWT 8.0;
- 1970–2011 analysis period and 1994 treatment;
- a Sub-Saharan African donor pool excluding Burundi, Democratic Republic of the Congo, Tanzania, and Uganda because of possible spillovers;
- PWT 8.0 human capital, PWT 7.1 investment and openness, WDI inflation, Polity IV, Freedom House political rights, and UCDP conflict events as predictors;
- 1985–1990 averages for most predictors and an additional 1991–1993 conflict average;
- normalized GDP in odd pre-treatment years through 1993 plus average GDP levels in 1985–1990;
- in-space placebos, a 1985 in-time placebo, and post/pre-RMSPE inference;
- exclusion from reported placebo inference when pre-treatment RMSPE exceeds the placebo median plus one standard deviation.

Published validation targets are pre-treatment RMSPE 0.0584, an estimated 1994 GDP gap near −0.58, and closure by 2011. The non-zero donor weights are Cameroon .254, Republic of the Congo .061, Gabon .149, Liberia .032, Lesotho .192, Mali .016, Niger .108, Sudan .014, and Senegal .175.

## Availability results

The [official PWT 8.0 archive](https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt8.0?lang=en) remains downloadable and covers 167 countries through 2011. A direct audit confirmed that Rwanda has non-missing `rgdpo` and `hc` for all 24 pre-treatment years from 1970–1993 and all 18 post-treatment years from 1994–2011. Thirty-nine eligible Sub-Saharan African donors have complete `rgdpo` coverage, and 27 have complete `hc` coverage.

The [official PWT 7.1 archive](https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt-7.1?lang=en) is also live. Historical WDI snapshots are available through the [World Bank archive](https://datatopics.worldbank.org/world-development-indicators/wdi-archives.html). [UCDP](https://ucdp.uu.se/downloads/) provides current and historical conflict data. [Freedom House](https://freedomhouse.org/report/freedom-world) provides historical country data, though access and reuse conditions must be recorded. The exact Polity IV vintage and precise UCDP aggregation still need to be frozen.

## Replication labels

- **Exact replication:** original code or fully matched historical inputs and preprocessing produce the reported values within declared numerical tolerance.
- **Close replication:** independently reconstructed code uses the named historical releases and documented design, with differences reported transparently.
- **Modern reconstruction:** newer data releases replace one or more original vintages.

The current classification is **close replication feasible**.

## Completed checkpoint: published-weight reconstruction

The published-weight reconstruction has now been run against both plausible PWT 8.0 GDP variables. Using `rgdpe` reproduces the central benchmarks: pre-treatment RMSPE 0.0574 versus the published 0.0584, a 1994 gap of −0.582 versus −0.58, and a 2011 gap of −0.004 versus approximately zero. Using the manuscript's stated `rgdpo` produces RMSPE 0.0999 and a 2011 gap of +0.431, so it does not reproduce the published recovery path.

This is evidence of an apparent variable-label inconsistency, not yet proof of an article error. The small remaining `rgdpe` differences are consistent with the published weights being rounded to three decimals and summing to 1.001. The complete series is in [`results/published-weight-replication.csv`](../results/published-weight-replication.csv), and the executable reconstruction is [`code/01_reconstruct_published_gdp.R`](../code/01_reconstruct_published_gdp.R).

## Execution sequence

1. **By 10 September:** save checksums and source metadata for PWT 8.0 and 7.1; create a machine-readable specification sheet.
2. **Completed 9 September:** reconstruct the published synthetic series and test both PWT 8.0 GDP concepts against the reported donor weights.
3. **By 12 September:** acquire and freeze WDI inflation, Polity IV, Freedom House, and UCDP predictor vintages; document every transformation.
4. **By 13 September:** estimate donor weights independently and compare weights, RMSPE, the 1994 gap, and 2011 closure against the published targets.
5. **Go/no-go:** proceed to the extension if the pre-treatment path and qualitative findings are reproduced. If exact weights differ, retain the project as a close replication and explain the vintage or preprocessing sensitivity.

The missing author code increases implementation time and makes exact numerical equality uncertain. It does not make the study infeasible. An author request for code and the original assembled data would be useful, but work need not wait for a reply.
