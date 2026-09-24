#!/usr/bin/env Rscript
# Placebo tests for the 9-country donor pool (the published-weight
# countries only), using the real Synth package -- not a hand-rolled fit.
# This is a restricted-pool SENSITIVITY check, not the headline placebo
# result: see code/10_synth_package_placebo_full_pool.R for the full
# 39-country test, which is the one to trust.
#
# In-space placebo: reassign the "treatment" to each donor country in
# turn and see how big a gap it gets by chance, compared to Rwanda's.
# In-time placebo: pretend the genocide happened in 1985 instead of 1994,
# and check whether a spurious gap opens up before it actually did.

library(readxl)  # to read the PWT 8.0 Excel file
library(Synth)   # the actual synthetic control package

# ---- 1. Load and prepare the data -----------------------------------------

pwt <- read_excel("data/raw/pwt80.xlsx", sheet = "Data")
pwt <- as.data.frame(pwt)

donors <- c("CMR", "COG", "GAB", "LBR", "LSO", "MLI", "NER", "SDN", "SEN")
treatment_year <- 1994
first_year <- 1970
last_year <- 2011
outcome_var <- "rgdpe"

panel <- pwt[pwt$countrycode %in% c("RWA", donors) & pwt$year %in% first_year:last_year,
             c("countrycode", "year", outcome_var)]
names(panel)[3] <- "gdp"

for (country in unique(panel$countrycode)) {
  is_this_country <- panel$countrycode == country
  baseline <- mean(panel$gdp[is_this_country & panel$year %in% 1991:1993])
  panel$gdp[is_this_country] <- panel$gdp[is_this_country] / baseline
}

panel$unit_id <- as.numeric(factor(panel$countrycode))
id_lookup <- unique(panel[, c("countrycode", "unit_id")])

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ---- 2. One function that fits a synthetic control for any unit/window ---
# treated_code: the country pretending to be treated.
# control_codes: the donor pool for that fit.
# pre_years / plot_years: the pre-treatment fitting window and the years
# to return (lets the same function do both the 1994 test and the fake
# 1985 test).

fit_one <- function(treated_code, control_codes, pre_years, plot_years) {
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
    time.predictors.prior = pre_years,
    time.optimize.ssr = pre_years,
    time.plot = plot_years,
    special.predictors = list(
      list("gdp", pre_years[1]:(pre_years[1] + 9), "mean"),
      list("gdp", (pre_years[1] + 10):(pre_years[1] + 19), "mean"),
      list("gdp", tail(pre_years, 4), "mean")
    )
  )

  fit <- synth(dp, quiet = TRUE)
  actual <- dp$Y1plot[, 1]
  synthetic <- as.numeric(dp$Y0plot %*% fit$solution.w)
  data.frame(year = plot_years, actual = actual, synthetic = synthetic, gap = actual - synthetic)
}

rmspe <- function(gap, mask) sqrt(mean(gap[mask]^2))

# ---- 3. In-space placebo: Rwanda, then every donor in turn ---------------

pre_years <- first_year:(treatment_year - 1)
plot_years <- first_year:last_year

run_in_space_unit <- function(treated) {
  pool <- setdiff(donors, treated)  # RWA's pool is all 9 donors; a donor's pool excludes itself
  res <- fit_one(treated, pool, pre_years, plot_years)
  pre_r <- rmspe(res$gap, res$year < treatment_year)
  post_r <- rmspe(res$gap, res$year >= treatment_year)
  list(unit = treated, res = res, ratio = post_r / pre_r, pre_rmspe = pre_r, post_rmspe = post_r)
}

rwanda_run <- run_in_space_unit("RWA")
placebo_runs <- lapply(donors, run_in_space_unit)

in_space <- do.call(rbind, lapply(c(list(rwanda_run), placebo_runs), function(r) {
  data.frame(unit = r$unit, pre_rmspe = r$pre_rmspe, post_rmspe = r$post_rmspe, ratio = r$ratio)
}))
in_space <- in_space[order(-in_space$ratio), ]
in_space$rank <- seq_len(nrow(in_space))
rwanda_rank <- in_space$rank[in_space$unit == "RWA"]
p_value <- rwanda_rank / nrow(in_space)
write.csv(in_space, "results/placebo-in-space.csv", row.names = FALSE)

# ---- 4. In-time placebo: pretend the treatment was in 1985 ----------------

fake_year <- 1985
fake_pre <- first_year:(fake_year - 1)
in_time <- fit_one("RWA", donors, fake_pre, plot_years)
in_time_pre_rmspe <- rmspe(in_time$gap, in_time$year < fake_year)
in_time_post_rmspe <- rmspe(in_time$gap, in_time$year >= fake_year & in_time$year < treatment_year)
in_time_ratio <- in_time_post_rmspe / in_time_pre_rmspe
write.csv(in_time, "results/placebo-in-time.csv", row.names = FALSE)

# ---- 5. Report --------------------------------------------------------------

lines <- c(
  "# Placebo tests, 9-country donor pool (Synth package)",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "This is a restricted-pool sensitivity check, not the headline placebo result -- see `results/synth-package-placebo-full-pool.csv` / `code/10` for the full 39-country test. Both in-space and in-time tests here use the actual `Synth` package.",
  "",
  "## In-space placebo",
  "",
  "| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |",
  "|------|------|-----------|------------|-------|",
  paste0(
    "| ", in_space$rank, " | ", in_space$unit, " | ",
    sprintf("%.4f", in_space$pre_rmspe), " | ",
    sprintf("%.4f", in_space$post_rmspe), " | ",
    sprintf("%.2f", in_space$ratio), " |",
    collapse = "\n"
  ),
  "",
  sprintf("**Rwanda's rank: %d of %d (p = %.3f).**", rwanda_rank, nrow(in_space), p_value),
  "",
  "## In-time placebo (fake treatment year: 1985)",
  "",
  sprintf("- Pre-1985 RMSPE: %.4f", in_time_pre_rmspe),
  sprintf("- 1985-1993 (placebo post) RMSPE: %.4f", in_time_post_rmspe),
  sprintf("- Ratio: %.2f", in_time_ratio)
)
writeLines(lines, "results/placebo-tests.md")

# ---- 6. Figures -------------------------------------------------------------

png("figures/placebo-in-space.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
all_gaps <- c(rwanda_run$res$gap, unlist(lapply(placebo_runs, function(r) r$res$gap)))
plot(
  NA, xlim = range(plot_years), ylim = range(all_gaps),
  xlab = "Year", ylab = "Gap (actual - synthetic)",
  main = "In-space placebo (9-country pool, Synth package)"
)
for (r in placebo_runs) lines(r$res$year, r$res$gap, col = "#9CA3AF", lwd = 1.2)
lines(rwanda_run$res$year, rwanda_run$res$gap, col = "#DC2626", lwd = 3)
abline(v = treatment_year, lty = 3, lwd = 2, col = "#111827")
abline(h = 0, lty = 1, lwd = 1, col = "#00000055")
legend(
  "bottomleft", legend = c("Rwanda", "Placebo donors", "1994 genocide"),
  col = c("#DC2626", "#9CA3AF", "#111827"), lty = c(1, 1, 3), lwd = c(3, 1.2, 2), bty = "n"
)
mtext("Restricted 9-country sensitivity check -- see code/10 for the full-pool headline test", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

png("figures/placebo-in-time.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  in_time$year, in_time$actual, type = "l", lwd = 3, col = "#111827",
  xlab = "Year", ylab = "Normalized GDP (1991-1993 average = 1)",
  main = "In-time placebo: fake 1985 treatment (Synth package)",
  ylim = range(c(in_time$actual, in_time$synthetic))
)
lines(in_time$year, in_time$synthetic, lwd = 3, lty = 2, col = "#2563EB")
abline(v = fake_year, lty = 3, lwd = 2, col = "#D97706")
abline(v = treatment_year, lty = 3, lwd = 2, col = "#DC2626")
legend(
  "topleft", legend = c("Rwanda", "Synthetic Rwanda (fit on 1970-1984)", "Fake 1985 treatment", "Real 1994 genocide"),
  col = c("#111827", "#2563EB", "#D97706", "#DC2626"), lty = c(1, 2, 3, 3), lwd = c(3, 3, 2, 2), bty = "n", cex = 0.8
)
mtext("Weights fit on 1970-1984 only; gap checked for 1985-1993 before the real treatment", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(lines, collapse = "\n"), "\n")
