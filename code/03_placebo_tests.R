#!/usr/bin/env Rscript

# Placebo-based inference for the Rwanda GDP synthetic control.
#
# In-space placebo: reassign the "treatment" to each donor country in turn
# (using the remaining donors, excluding Rwanda, as its synthetic control)
# and compare Rwanda's post/pre RMSPE ratio to the resulting placebo
# distribution (Abadie, Diamond & Hainmueller 2010 style rank inference).
#
# In-time placebo: pretend the treatment happened in 1985 instead of 1994,
# fit weights on the pre-1985 window only, and check whether a spurious gap
# opens up before the genocide actually occurred.
#
# Uses the same 9-country donor pool as the published weights (not the full
# ~39-country Sub-Saharan Africa pool from docs/replication-feasibility.md).
# Fast version: flags the full donor-pool placebo run as a follow-up, not
# required for this checkpoint.

suppressPackageStartupMessages({
  library(readxl)
  library(quadprog)
})

data_file <- "data/raw/pwt80.xlsx"
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
stopifnot(file.exists(data_file)) # produced by code/02_reestimate_weights.R

pwt <- as.data.frame(read_excel(data_file, sheet = "Data"))

donors <- c("CMR", "COG", "GAB", "LBR", "LSO", "MLI", "NER", "SDN", "SEN")
all_units <- c("RWA", donors)
treatment_year <- 1994
full_years <- 1970:2011
variable <- "rgdpe"

keep <- pwt$countrycode %in% all_units & pwt$year %in% full_years
panel <- pwt[keep, c("countrycode", "year", variable)]
names(panel)[3] <- "value"
panel$normalized <- NA_real_
for (code in unique(panel$countrycode)) {
  is_country <- panel$countrycode == code
  base <- mean(panel$value[is_country & panel$year %in% 1991:1993])
  panel$normalized[is_country] <- panel$value[is_country] / base
}

wide <- reshape(
  panel[, c("countrycode", "year", "normalized")],
  idvar = "year", timevar = "countrycode", direction = "wide"
)
names(wide) <- sub("^normalized\\.", "", names(wide))
wide <- wide[order(wide$year), ]

fit_synthetic <- function(target, pool, pre_years, wide_data) {
  pre <- wide_data[wide_data$year %in% pre_years, ]
  X <- as.matrix(pre[, pool])
  y <- pre[[target]]
  Dmat <- t(X) %*% X + diag(1e-8, length(pool))
  dvec <- t(X) %*% y
  Amat <- cbind(rep(1, length(pool)), diag(length(pool)))
  bvec <- c(1, rep(0, length(pool)))
  qp <- solve.QP(Dmat, dvec, Amat, bvec, meq = 1)
  w <- pmax(qp$solution, 0)
  w <- w / sum(w)
  setNames(w, pool)
}

rmspe <- function(gap, years, res) sqrt(mean(gap[res$year %in% years]^2))

# ---- In-space placebo -------------------------------------------------

pre_years <- 1970:(treatment_year - 1)
post_years <- treatment_year:2011

run_unit <- function(target, pool) {
  w <- fit_synthetic(target, pool, pre_years, wide)
  synthetic <- vapply(wide$year, function(yr) {
    row <- wide[wide$year == yr, pool]
    sum(w * as.numeric(row))
  }, numeric(1))
  res <- data.frame(year = wide$year, actual = wide[[target]], synthetic = synthetic)
  res$gap <- res$actual - res$synthetic
  pre_r <- rmspe(res$gap, pre_years, res)
  post_r <- rmspe(res$gap, post_years, res)
  list(unit = target, res = res, pre_rmspe = pre_r, post_rmspe = post_r, ratio = post_r / pre_r)
}

rwanda_run <- run_unit("RWA", donors)
placebo_runs <- lapply(donors, function(d) run_unit(d, setdiff(donors, d)))

in_space <- do.call(rbind, lapply(c(list(rwanda_run), placebo_runs), function(r) {
  data.frame(unit = r$unit, pre_rmspe = r$pre_rmspe, post_rmspe = r$post_rmspe, ratio = r$ratio)
}))
in_space <- in_space[order(-in_space$ratio), ]
in_space$rank <- seq_len(nrow(in_space))
rwanda_rank <- in_space$rank[in_space$unit == "RWA"]
p_value <- rwanda_rank / nrow(in_space)

write.csv(in_space, "results/placebo-in-space.csv", row.names = FALSE)

# ---- In-time placebo (fake treatment: 1985) ----------------------------

fake_year <- 1985
fake_pre <- 1970:(fake_year - 1)
fake_post <- fake_year:(treatment_year - 1) # stop before the real treatment

w_fake <- fit_synthetic("RWA", donors, fake_pre, wide)
synthetic_fake <- vapply(wide$year, function(yr) {
  row <- wide[wide$year == yr, donors]
  sum(w_fake * as.numeric(row))
}, numeric(1))
in_time <- data.frame(year = wide$year, actual = wide$RWA, synthetic = synthetic_fake)
in_time$gap <- in_time$actual - in_time$synthetic
in_time_pre_rmspe <- rmspe(in_time$gap, fake_pre, in_time)
in_time_post_rmspe <- rmspe(in_time$gap, fake_post, in_time)
in_time_ratio <- in_time_post_rmspe / in_time_pre_rmspe

write.csv(in_time, "results/placebo-in-time.csv", row.names = FALSE)

# ---- Report -------------------------------------------------------------

lines <- c(
  "# Placebo tests and RMSPE-based inference",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "## In-space placebo (donor permutations)",
  "",
  "Each donor country is treated as if it were the treated unit, using the remaining 8 donors (Rwanda excluded) as its synthetic control, over the same 1970-1993 pre-period. Ranking all 9 units plus Rwanda by post/pre RMSPE ratio gives a permutation-style p-value (rank / number of units).",
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
  sprintf("**Rwanda's rank: %d of %d (p = %.3f).** ", rwanda_rank, nrow(in_space), p_value),
  if (rwanda_rank == 1) {
    "Rwanda has the largest post/pre RMSPE ratio of any unit in the donor pool, i.e. no placebo country shows a gap this extreme relative to its own pre-treatment fit. This supports treating the 1994 GDP gap as unusual rather than attributable to ordinary cross-country variation."
  } else {
    sprintf(
      "Rwanda is not the most extreme unit (%d placebo unit(s) show a larger ratio). This weakens (without eliminating) the inferential case relative to a rank-1 result and should be reported honestly rather than reframed.",
      rwanda_rank - 1
    )
  },
  "",
  "**Caveat:** this uses the same 9-country donor pool as the published weights, not the full ~39-country Sub-Saharan Africa donor pool described in `docs/replication-feasibility.md`. A larger placebo pool is a follow-up robustness check, not required for this checkpoint.",
  "",
  "## In-time placebo (fake treatment year: 1985)",
  "",
  sprintf("Fitting a synthetic Rwanda on 1970-%d only and checking for a spurious gap between %d and %d (before the real 1994 genocide):", fake_year - 1, fake_year, treatment_year - 1),
  "",
  sprintf("- Pre-1985 RMSPE: %.4f", in_time_pre_rmspe),
  sprintf("- 1985-1993 (placebo post) RMSPE: %.4f", in_time_post_rmspe),
  sprintf("- Ratio: %.2f", in_time_ratio),
  "",
  if (in_time_ratio < 2) {
    "The ratio is small, i.e. no meaningful gap opens up between the fake 1985 treatment and the real 1994 genocide. This is consistent with the 1994 effect being a genuine break rather than a pre-existing trend."
  } else {
    "The ratio is non-trivial, suggesting some divergence between Rwanda and its synthetic control even before 1994. This should be reported and discussed as a limitation rather than omitted."
  },
  "",
  "## Still not done (flagged, not blocking this checkpoint)",
  "",
  "- Full ~39-country Sub-Saharan Africa donor pool for in-space placebos (currently limited to the 9 published-weight donors).",
  "- Placebo tests using the re-estimated (rather than published) donor weights.",
  "- Formal confidence intervals beyond the rank-based p-value."
)
writeLines(lines, "results/placebo-tests.md")

png("figures/placebo-in-space.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
all_gaps <- c(rwanda_run$res$gap, unlist(lapply(placebo_runs, function(r) r$res$gap)))
plot(
  NA, xlim = range(wide$year), ylim = range(all_gaps),
  xlab = "Year", ylab = "Gap (actual - synthetic)",
  main = "In-space placebo: Rwanda vs. donor-country placebo gaps"
)
for (r in placebo_runs) lines(r$res$year, r$res$gap, col = "#9CA3AF", lwd = 1.2)
lines(rwanda_run$res$year, rwanda_run$res$gap, col = "#DC2626", lwd = 3)
abline(v = treatment_year, lty = 3, lwd = 2, col = "#111827")
abline(h = 0, lty = 1, lwd = 1, col = "#00000055")
legend(
  "bottomleft", legend = c("Rwanda", "Placebo donors", "1994 genocide"),
  col = c("#DC2626", "#9CA3AF", "#111827"), lty = c(1, 1, 3), lwd = c(3, 1.2, 2), bty = "n"
)
mtext("Each grey line reassigns treatment to one donor country using the other 8 as its synthetic control", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

png("figures/placebo-in-time.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  in_time$year, in_time$actual, type = "l", lwd = 3, col = "#111827",
  xlab = "Year", ylab = "Normalized GDP (1991-1993 average = 1)",
  main = "In-time placebo: fake 1985 treatment",
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
