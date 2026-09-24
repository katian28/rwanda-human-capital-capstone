#!/usr/bin/env Rscript
# Rwanda GDP synthetic control, using the real Synth package
# (written by Abadie, Diamond & Hainmueller -- the people who invented
# this method). No custom math here: dataprep() and synth() do the
# actual estimation, and synth.tab()/path.plot()/gaps.plot() (also from
# the Synth package) build the table and plots. Every line is commented.

library(readxl)  # to read the PWT 8.0 Excel file
library(Synth)   # the actual synthetic control package

# ---- 1. Load the raw data -------------------------------------------------

pwt <- read_excel("data/raw/pwt80.xlsx", sheet = "Data")  # Penn World Table 8.0
pwt <- as.data.frame(pwt)  # Synth wants a plain data.frame, not a tibble

# ---- 2. Set up the countries, years, and outcome variable ------------------

# Hodler's published donor weights are only non-zero for these 9 countries,
# so this is the donor pool for the replication.
donors <- c("CMR", "COG", "GAB", "LBR", "LSO", "MLI", "NER", "SDN", "SEN")

treatment_year <- 1994  # the genocide
first_year <- 1970      # start of the data window
last_year <- 2011        # end of the data window
outcome_var <- "rgdpe"   # real GDP, expenditure side (see results/replication-validation.md for why rgdpe, not rgdpo)

# Keep only Rwanda + the 9 donors, and only the years we need.
keep_rows <- pwt$countrycode %in% c("RWA", donors) & pwt$year %in% first_year:last_year
panel <- pwt[keep_rows, c("countrycode", "year", outcome_var)]
names(panel)[3] <- "gdp"  # rename the outcome column to something simple

# ---- 3. Normalize GDP so 1991-1993 average = 1 -----------------------------
# This matches how the rest of this project reports GDP (as a ratio to the
# pre-genocide baseline), so the numbers below are comparable to the other
# scripts. Synth itself does not require this step -- it works on raw
# levels too -- but comparability across scripts is worth the extra step.

for (country in unique(panel$countrycode)) {
  is_this_country <- panel$countrycode == country
  baseline <- mean(panel$gdp[is_this_country & panel$year %in% 1991:1993])
  panel$gdp[is_this_country] <- panel$gdp[is_this_country] / baseline
}

# ---- 4. Synth needs a NUMBER for each country, not a text code ------------

panel$unit_id <- as.numeric(factor(panel$countrycode))  # e.g. RWA -> 1, CMR -> 2, ...
rwanda_id <- panel$unit_id[panel$countrycode == "RWA"][1]  # Rwanda's number
donor_ids <- unique(panel$unit_id[panel$countrycode %in% donors])  # the donors' numbers

# ---- 5. dataprep(): package the data the way synth() expects it ------------
# This is the standard Synth workflow: dataprep() first, then synth().

dataprep_out <- dataprep(
  foo = panel,                          # our data
  dependent = "gdp",                    # the outcome we're matching/predicting
  unit.variable = "unit_id",            # numeric country ID column
  unit.names.variable = "countrycode",  # text country code column (for labels)
  time.variable = "year",               # the year column
  treatment.identifier = rwanda_id,     # which unit is "treated" (Rwanda)
  controls.identifier = donor_ids,      # which units can be used to build the synthetic control
  time.predictors.prior = first_year:(treatment_year - 1),  # pre-treatment years used to fit the weights
  time.optimize.ssr = first_year:(treatment_year - 1),      # same window, used to choose the best-fitting weights
  time.plot = first_year:last_year,     # years to include in the output/plots (pre AND post treatment)
  # special.predictors: what the synthetic control tries to match before 1994.
  # We use GDP's own average in three sub-periods (rather than one single
  # average) because we don't yet have Hodler's full predictor set (PWT 7.1
  # investment/openness, WDI inflation, Polity IV, Freedom House, UCDP
  # conflict data) assembled -- see docs/replication-feasibility.md.
  special.predictors = list(
    list("gdp", 1970:1979, "mean"),  # average GDP, 1970s
    list("gdp", 1980:1989, "mean"),  # average GDP, 1980s
    list("gdp", 1990:1993, "mean")   # average GDP, just before the genocide
  )
)

# ---- 6. synth(): the actual optimization that picks the donor weights -----

synth_out <- synth(dataprep_out)  # this is the one line that does the real work

# ---- 7. Look at the results, using Synth's own built-in tools -------------

# synth.tab() prints a clean table: donor weights, and how much each
# special predictor mattered (its "V weight").
print(synth.tab(synth.res = synth_out, dataprep.res = dataprep_out))

# path.plot(): Rwanda's actual GDP vs. the synthetic control's GDP, over time.
dir.create("figures", showWarnings = FALSE)
png("figures/gdp-reestimated-path.png", width = 1400, height = 900, res = 150)
path.plot(
  synth.res = synth_out,
  dataprep.res = dataprep_out,
  Ylab = "Normalized GDP (1991-1993 average = 1)",
  Xlab = "Year",
  Main = "Rwanda GDP: actual vs. independently re-estimated synthetic",
  Legend = c("Rwanda", "Synthetic Rwanda")
)
abline(v = treatment_year, lty = 3, col = "red")  # mark the genocide year
dev.off()

# gaps.plot(): just the gap (actual minus synthetic) over time.
png("figures/gdp-reestimated-gaps.png", width = 1400, height = 900, res = 150)
gaps.plot(
  synth.res = synth_out,
  dataprep.res = dataprep_out,
  Ylab = "Gap (actual - synthetic)",
  Xlab = "Year",
  Main = "Rwanda GDP gap (independently re-estimated weights)"
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

# ---- 8. Save the numbers other scripts/the paper can use -------------------

dir.create("results", showWarnings = FALSE)

# Donor weights, compared to the published weights.
published_weights <- c(
  CMR = 0.254, COG = 0.061, GAB = 0.149, LBR = 0.032, LSO = 0.192,
  MLI = 0.016, NER = 0.108, SDN = 0.014, SEN = 0.175
)
weights_table <- data.frame(
  donor = donors,
  published_weight = as.numeric(published_weights[donors]),
  synth_weight = round(as.numeric(synth_out$solution.w), 4)
)
write.csv(weights_table, "results/gdp-reestimated-weights.csv", row.names = FALSE)

# Actual vs. synthetic GDP, year by year.
actual <- dataprep_out$Y1plot[, 1]                              # Rwanda's real path
synthetic <- as.numeric(dataprep_out$Y0plot %*% synth_out$solution.w)  # weighted average of donors
path_table <- data.frame(year = first_year:last_year, actual = actual, synthetic = synthetic)
path_table$gap <- path_table$actual - path_table$synthetic
write.csv(path_table, "results/gdp-reestimated-path.csv", row.names = FALSE)

# Quick headline numbers, printed so they show up when this script runs.
pre_years <- path_table$year < treatment_year
pre_treatment_rmspe <- sqrt(mean(path_table$gap[pre_years]^2))
gap_1994 <- path_table$gap[path_table$year == 1994]
gap_2011 <- path_table$gap[path_table$year == 2011]
cat("\nPre-treatment RMSPE:", round(pre_treatment_rmspe, 4), "\n")
cat("1994 gap:", round(gap_1994, 3), "\n")
cat("2011 gap:", round(gap_2011, 3), "\n")
