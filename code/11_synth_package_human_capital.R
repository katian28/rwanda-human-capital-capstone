#!/usr/bin/env Rscript
# Human-capital extension, using the real Synth package instead of the
# custom quadratic program in code/05_human_capital_extension.R.
# Same two steps as the GDP version (code/09 and code/10): first fit
# Rwanda's synthetic control and look at the gap, then run the same fit
# for every donor country as a placebo to see how unusual Rwanda's gap
# really is.

library(readxl)  # to read the PWT 8.0 Excel file
library(Synth)   # the actual synthetic control package

# ---- 1. Load the raw data -------------------------------------------------

pwt <- read_excel("data/raw/pwt80.xlsx", sheet = "Data")
pwt <- as.data.frame(pwt)

# ---- 2. Build the 27-country donor pool (same screening as code/05) ------
# Same Sub-Saharan Africa candidate list as the GDP version, but kept only
# if the country has complete "hc" (human capital index) data, not rgdpe.

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
outcome_var <- "hc"  # PWT human-capital index, not rgdpe

coverage <- pwt[pwt$countrycode %in% candidates & pwt$year %in% first_year:last_year, ]
complete_years <- tapply(!is.na(coverage[[outcome_var]]), coverage$countrycode, sum)
donors <- names(complete_years)[complete_years == length(first_year:last_year)]
cat(length(donors), "donors have complete hc coverage\n")

# ---- 3. Build and normalize the panel (Rwanda + all donors) ---------------

panel <- pwt[pwt$countrycode %in% c("RWA", donors) & pwt$year %in% first_year:last_year,
             c("countrycode", "year", outcome_var)]
names(panel)[3] <- "hc_index"

for (country in unique(panel$countrycode)) {
  is_this_country <- panel$countrycode == country
  baseline <- mean(panel$hc_index[is_this_country & panel$year %in% 1991:1993])
  panel$hc_index[is_this_country] <- panel$hc_index[is_this_country] / baseline
}

panel$unit_id <- as.numeric(factor(panel$countrycode))
id_lookup <- unique(panel[, c("countrycode", "unit_id")])

# ---- 4. Fit Rwanda's synthetic control (the main result) ------------------

rwanda_id <- id_lookup$unit_id[id_lookup$countrycode == "RWA"]
donor_ids <- id_lookup$unit_id[id_lookup$countrycode %in% donors]

dp_main <- dataprep(
  foo = panel,
  dependent = "hc_index",
  unit.variable = "unit_id",
  unit.names.variable = "countrycode",
  time.variable = "year",
  treatment.identifier = rwanda_id,
  controls.identifier = donor_ids,
  time.predictors.prior = first_year:(treatment_year - 1),
  time.optimize.ssr = first_year:(treatment_year - 1),
  time.plot = first_year:last_year,
  special.predictors = list(
    list("hc_index", 1970:1979, "mean"),
    list("hc_index", 1980:1989, "mean"),
    list("hc_index", 1990:1993, "mean")
  )
)

synth_main <- synth(dp_main)

print(synth.tab(synth.res = synth_main, dataprep.res = dp_main))

dir.create("figures", showWarnings = FALSE)
png("figures/synth-package-hc-path.png", width = 1400, height = 900, res = 150)
path.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "Normalized human capital index (1991-1993 average = 1)",
  Xlab = "Year",
  Main = "Rwanda human capital: actual vs. synthetic (Synth package)",
  Legend = c("Rwanda", "Synthetic Rwanda")
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

png("figures/synth-package-hc-gaps.png", width = 1400, height = 900, res = 150)
gaps.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "Gap (actual - synthetic)",
  Xlab = "Year",
  Main = "Rwanda human capital gap (Synth package)"
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

dir.create("results", showWarnings = FALSE)
actual_main <- dp_main$Y1plot[, 1]
synthetic_main <- as.numeric(dp_main$Y0plot %*% synth_main$solution.w)
path_table <- data.frame(year = first_year:last_year, actual = actual_main, synthetic = synthetic_main)
path_table$gap <- path_table$actual - path_table$synthetic
write.csv(path_table, "results/synth-package-hc-path.csv", row.names = FALSE)

weights_table <- data.frame(donor = donors, synth_weight = round(as.numeric(synth_main$solution.w), 4))
write.csv(weights_table, "results/synth-package-hc-weights.csv", row.names = FALSE)

pre_rmspe_main <- sqrt(mean(path_table$gap[path_table$year < treatment_year]^2))
post_gap_main <- path_table$gap[path_table$year >= treatment_year]
cat("\nMain result -- pre-treatment RMSPE:", round(pre_rmspe_main, 5), "\n")
cat("Average post-treatment gap:", round(mean(post_gap_main), 3), "\n")

# ---- 5. Placebo test: run the same fit for every donor as if IT were treated

fit_one_unit <- function(treated_code, control_codes) {
  treated_id <- id_lookup$unit_id[id_lookup$countrycode == treated_code]
  control_ids <- id_lookup$unit_id[id_lookup$countrycode %in% control_codes]

  dp <- dataprep(
    foo = panel,
    dependent = "hc_index",
    unit.variable = "unit_id",
    unit.names.variable = "countrycode",
    time.variable = "year",
    treatment.identifier = treated_id,
    controls.identifier = control_ids,
    time.predictors.prior = first_year:(treatment_year - 1),
    time.optimize.ssr = first_year:(treatment_year - 1),
    time.plot = first_year:last_year,
    special.predictors = list(
      list("hc_index", 1970:1979, "mean"),
      list("hc_index", 1980:1989, "mean"),
      list("hc_index", 1990:1993, "mean")
    )
  )

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

all_units <- c("RWA", donors)
cat("\nFitting", length(all_units), "synthetic controls for the placebo test...\n")

placebo_results <- data.frame()
for (treated in all_units) {
  others <- setdiff(donors, treated)
  one_result <- fit_one_unit(treated, others)
  placebo_results <- rbind(placebo_results, one_result)
  cat(".")
}
cat("\n")

placebo_results <- placebo_results[order(-placebo_results$ratio), ]
placebo_results$rank <- seq_len(nrow(placebo_results))
rwanda_rank <- placebo_results$rank[placebo_results$unit == "RWA"]
p_value <- rwanda_rank / nrow(placebo_results)

write.csv(placebo_results, "results/synth-package-hc-placebo.csv", row.names = FALSE)

cat("\nRwanda's placebo rank:", rwanda_rank, "of", nrow(placebo_results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(placebo_results, 6))
