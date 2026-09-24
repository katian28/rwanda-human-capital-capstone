#!/usr/bin/env Rscript
# Full 39-country GDP placebo test, using the real Synth package. This is
# the headline placebo result for the paper (not the smaller 9-country
# version in code/03, which is a restricted-pool sensitivity check).
# Same idea as code/09: treat each country in turn as if IT were hit by
# the genocide in 1994, fit a synthetic control for it from the other
# countries, and see how big its "fake" gap is. If Rwanda's real gap is
# not bigger than most of these fake gaps, that's evidence the gap is not
# statistically unusual. Section 7 adds an in-time placebo (fake 1985
# treatment) using the same full donor pool.

library(readxl)  # to read the PWT 8.0 Excel file
library(Synth)   # the actual synthetic control package

# ---- 1. Load the raw data -------------------------------------------------

pwt <- read_excel("data/raw/pwt80.xlsx", sheet = "Data")
pwt <- as.data.frame(pwt)

# ---- 2. Build the same 39-country donor pool as code/04 -------------------
# Sub-Saharan Africa, minus Rwanda (treated) and Burundi/DRC/Tanzania/Uganda
# (excluded for spillover risk -- see docs/replication-feasibility.md),
# then kept only if it has complete rgdpe data for every year 1970-2011.

ssa_all <- c(
  "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD", "COM",
  "COD", "COG", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA",
  "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
  "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM",
  "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE"
)
excluded <- c("BDI", "COD", "TZA", "UGA")
candidates <- setdiff(ssa_all, c("RWA", excluded))

treatment_year <- 1994
first_year <- 1970
last_year <- 2011
outcome_var <- "rgdpe"

coverage <- pwt[pwt$countrycode %in% candidates & pwt$year %in% first_year:last_year, ]
complete_years <- tapply(!is.na(coverage[[outcome_var]]), coverage$countrycode, sum)
donors <- names(complete_years)[complete_years == length(first_year:last_year)]
cat(length(donors), "donors have complete rgdpe coverage\n")

# ---- 3. Build and normalize the panel (Rwanda + all donors) ---------------

panel <- pwt[pwt$countrycode %in% c("RWA", donors) & pwt$year %in% first_year:last_year,
             c("countrycode", "year", outcome_var)]
names(panel)[3] <- "gdp"

for (country in unique(panel$countrycode)) {
  is_this_country <- panel$countrycode == country
  baseline <- mean(panel$gdp[is_this_country & panel$year %in% 1991:1993])
  panel$gdp[is_this_country] <- panel$gdp[is_this_country] / baseline
}

panel$unit_id <- as.numeric(factor(panel$countrycode))  # Synth needs numeric IDs
id_lookup <- unique(panel[, c("countrycode", "unit_id")])  # country code -> number

# ---- 4. One function that fits a synthetic control for ANY treated unit --
# This is the same dataprep() + synth() recipe as code/09, just wrapped in
# a function so we can re-use it for all 40 units (Rwanda + 39 donors)
# without copy-pasting the same code 40 times.

fit_one_unit <- function(treated_code, control_codes) {
  treated_id <- id_lookup$unit_id[id_lookup$countrycode == treated_code]
  control_ids <- id_lookup$unit_id[id_lookup$countrycode %in% control_codes]

  dp <- dataprep(
    foo = panel,
    dependent = "gdp",
    unit.variable = "unit_id",
    unit.names.variable = "countrycode",
    time.variable = "year",
    treatment.identifier = treated_id,
    controls.identifier = control_ids,
    time.predictors.prior = first_year:(treatment_year - 1),
    time.optimize.ssr = first_year:(treatment_year - 1),
    time.plot = first_year:last_year,
    special.predictors = list(
      list("gdp", 1970:1979, "mean"),
      list("gdp", 1980:1989, "mean"),
      list("gdp", 1990:1993, "mean")
    )
  )

  # quiet = TRUE stops synth() from printing progress for all 40 units
  fit <- synth(dp, quiet = TRUE)

  actual <- dp$Y1plot[, 1]
  synthetic <- as.numeric(dp$Y0plot %*% fit$solution.w)
  gap <- actual - synthetic

  years <- first_year:last_year
  pre_rmspe <- sqrt(mean(gap[years < treatment_year]^2))
  post_rmspe <- sqrt(mean(gap[years >= treatment_year]^2))

  data.frame(unit = treated_code, pre_rmspe = pre_rmspe, post_rmspe = post_rmspe,
             ratio = post_rmspe / pre_rmspe)
}

# ---- 5. Run it for Rwanda, then for every donor country as a placebo -----

all_units <- c("RWA", donors)
cat("Fitting", length(all_units), "synthetic controls (this takes a few minutes)...\n")

results <- data.frame()
for (treated in all_units) {
  others <- setdiff(donors, treated)  # every OTHER donor becomes that unit's control pool
  one_result <- fit_one_unit(treated, others)
  results <- rbind(results, one_result)
  cat(".")  # progress dot so we know it's still running
}
cat("\n")

# ---- 6. Rank everyone by their ratio, find Rwanda's rank ------------------

results <- results[order(-results$ratio), ]
results$rank <- seq_len(nrow(results))
rwanda_rank <- results$rank[results$unit == "RWA"]
p_value <- rwanda_rank / nrow(results)

dir.create("results", showWarnings = FALSE)
write.csv(results, "results/synth-package-placebo-full-pool.csv", row.names = FALSE)

cat("\nRwanda's rank:", rwanda_rank, "of", nrow(results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(results, 6))

# ---- 7. In-time placebo: pretend the treatment was in 1985 ----------------
# Same full 39-country pool, but fit weights on 1970-1984 only, then check
# 1985-1993 for a spurious gap before the real 1994 genocide.

fake_year <- 1985
fake_pre <- first_year:(fake_year - 1)

dp_fake <- dataprep(
  foo = panel,
  dependent = "gdp",
  unit.variable = "unit_id",
  unit.names.variable = "countrycode",
  time.variable = "year",
  treatment.identifier = id_lookup$unit_id[id_lookup$countrycode == "RWA"],
  controls.identifier = id_lookup$unit_id[id_lookup$countrycode %in% donors],
  time.predictors.prior = fake_pre,
  time.optimize.ssr = fake_pre,
  time.plot = first_year:last_year,
  special.predictors = list(
    list("gdp", 1970:1979, "mean"),
    list("gdp", fake_pre[length(fake_pre) - 4]:fake_pre[length(fake_pre)], "mean")
  )
)
fit_fake <- synth(dp_fake, quiet = TRUE)
actual_fake <- dp_fake$Y1plot[, 1]
synthetic_fake <- as.numeric(dp_fake$Y0plot %*% fit_fake$solution.w)
gap_fake <- actual_fake - synthetic_fake
years <- first_year:last_year

in_time_pre_rmspe <- sqrt(mean(gap_fake[years < fake_year]^2))
in_time_post_rmspe <- sqrt(mean(gap_fake[years >= fake_year & years < treatment_year]^2))
in_time_ratio <- in_time_post_rmspe / in_time_pre_rmspe

write.csv(
  data.frame(year = years, actual = actual_fake, synthetic = synthetic_fake, gap = gap_fake),
  "results/synth-package-placebo-in-time-full-pool.csv", row.names = FALSE
)
cat("\nIn-time placebo (fake 1985 treatment, full pool):\n")
cat("Pre-1985 RMSPE:", round(in_time_pre_rmspe, 4), "\n")
cat("1985-1993 RMSPE:", round(in_time_post_rmspe, 4), "\n")
cat("Ratio:", round(in_time_ratio, 2), "\n")
