#!/usr/bin/env Rscript

# Placebo tests using the full Sub-Saharan Africa donor pool, not just the
# 9 countries that received non-zero published weight (see
# results/placebo-tests.md for the 9-country version and its caveat that a
# fuller pool was a follow-up, not required for that checkpoint).
#
# Donor-pool construction follows docs/replication-feasibility.md: "a
# Sub-Saharan African donor pool excluding Burundi, Democratic Republic of
# the Congo, Tanzania, and Uganda because of possible spillovers" (43
# candidates), filtered here to countries with complete PWT 8.0 rgdpe
# coverage for 1970-2011, matching the "39 eligible... donors have complete
# rgdpo coverage" count in docs/replication-feasibility.md (we use rgdpe,
# per results/replication-validation.md's finding that rgdpe, not rgdpo,
# reproduces the published path).

suppressPackageStartupMessages({
  library(readxl)
  library(quadprog)
})

data_file <- "data/raw/pwt80.xlsx"
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
stopifnot(file.exists(data_file))

pwt <- as.data.frame(read_excel(data_file, sheet = "Data"))

# Sub-Saharan Africa (World Bank classification), minus Rwanda (treated) and
# Burundi/DRC/Tanzania/Uganda (excluded for spillover risk) = 43 candidates.
ssa_all <- c(
  "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD", "COM",
  "COD", "COG", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA",
  "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
  "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM",
  "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE"
)
excluded_spillover <- c("BDI", "COD", "TZA", "UGA")
candidates <- setdiff(ssa_all, c("RWA", excluded_spillover))

treatment_year <- 1994
full_years <- 1970:2011
variable <- "rgdpe"

# Screen candidates for complete rgdpe coverage over the full window.
coverage <- pwt[pwt$countrycode %in% candidates & pwt$year %in% full_years, c("countrycode", "year", variable)]
complete_counts <- tapply(!is.na(coverage[[variable]]), coverage$countrycode, sum)
eligible <- names(complete_counts)[complete_counts == length(full_years)]
dropped <- setdiff(candidates, eligible)

cat(sprintf("Candidates: %d. Eligible (complete rgdpe %d-%d): %d. Dropped for missingness: %s\n",
  length(candidates), min(full_years), max(full_years), length(eligible), paste(dropped, collapse = ", ")))

donors <- sort(eligible)
all_units <- c("RWA", donors)

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
  Dmat <- t(X) %*% X + diag(1e-6, length(pool))
  dvec <- t(X) %*% y
  Amat <- cbind(rep(1, length(pool)), diag(length(pool)))
  bvec <- c(1, rep(0, length(pool)))
  qp <- solve.QP(Dmat, dvec, Amat, bvec, meq = 1)
  w <- pmax(qp$solution, 0)
  w <- w / sum(w)
  setNames(w, pool)
}

rmspe <- function(gap, years, res) sqrt(mean(gap[res$year %in% years]^2))

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
  list(unit = target, res = res, weights = w, pre_rmspe = pre_r, post_rmspe = post_r, ratio = post_r / pre_r)
}

cat("Fitting placebo units (this takes a moment with", length(donors), "donors)...\n")
rwanda_run <- run_unit("RWA", donors)
placebo_runs <- lapply(donors, function(d) run_unit(d, setdiff(donors, d)))

in_space <- do.call(rbind, lapply(c(list(rwanda_run), placebo_runs), function(r) {
  data.frame(unit = r$unit, pre_rmspe = r$pre_rmspe, post_rmspe = r$post_rmspe, ratio = r$ratio)
}))
in_space <- in_space[order(-in_space$ratio), ]
in_space$rank <- seq_len(nrow(in_space))
rwanda_rank <- in_space$rank[in_space$unit == "RWA"]
p_value <- rwanda_rank / nrow(in_space)

write.csv(in_space, "results/placebo-in-space-full.csv", row.names = FALSE)

fake_year <- 1985
fake_pre <- 1970:(fake_year - 1)
fake_post <- fake_year:(treatment_year - 1)

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

write.csv(in_time, "results/placebo-in-time-full.csv", row.names = FALSE)

top10 <- head(in_space, 10)
lines <- c(
  "# Placebo tests, full Sub-Saharan Africa donor pool",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "## Donor pool construction",
  "",
  sprintf("Sub-Saharan Africa (World Bank classification) minus Rwanda (treated) and Burundi, DRC, Tanzania, and Uganda (excluded for spillover risk, per `docs/replication-feasibility.md`) gives %d candidates. Screening for complete PWT 8.0 `rgdpe` coverage over 1970-2011 leaves %d eligible donors.", length(candidates), length(donors)),
  sprintf("Dropped for incomplete `rgdpe` coverage: %s.", paste(dropped, collapse = ", ")),
  "",
  "## In-space placebo (full pool)",
  "",
  sprintf("Each of the %d units (Rwanda plus %d donors) is reassigned as the treated unit in turn, fit against the remaining units in the pool, and ranked by post/pre RMSPE ratio.", nrow(in_space), length(donors)),
  "",
  "**Top 10 by ratio:**",
  "",
  "| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |",
  "|------|------|-----------|------------|-------|",
  paste0(
    "| ", top10$rank, " | ", top10$unit, " | ",
    sprintf("%.4f", top10$pre_rmspe), " | ",
    sprintf("%.4f", top10$post_rmspe), " | ",
    sprintf("%.2f", top10$ratio), " |",
    collapse = "\n"
  ),
  "",
  sprintf("**Rwanda's rank: %d of %d (p = %.3f).**", rwanda_rank, nrow(in_space), p_value),
  if (p_value <= 0.10) {
    "This clears the conventional 10% rank-based placebo threshold: Rwanda's gap is among the most extreme in the full donor pool, not just relative to the 9 countries that received non-zero published weight."
  } else {
    "This does not clear the conventional 10% rank-based placebo threshold. Expanding the donor pool weakens, rather than strengthens, the placebo case relative to the 9-country version — report this directly rather than reverting to the smaller pool to get a better-looking rank."
  },
  "",
  "## In-time placebo (fake treatment year: 1985), full pool",
  "",
  sprintf("- Pre-1985 RMSPE: %.4f", in_time_pre_rmspe),
  sprintf("- 1985-1993 (placebo post) RMSPE: %.4f", in_time_post_rmspe),
  sprintf("- Ratio: %.2f", in_time_ratio),
  "",
  "## Comparison to the 9-country version",
  "",
  "See `results/placebo-tests.md` for the 9-country donor pool (published-weight countries only), where Rwanda ranked 3rd of 10 (p = 0.30) in-space and showed an in-time ratio of 4.27. Report both versions in the paper; do not present only the more favorable one."
)
writeLines(lines, "results/placebo-tests-full.md")

png("figures/placebo-in-space-full.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
all_gaps <- c(rwanda_run$res$gap, unlist(lapply(placebo_runs, function(r) r$res$gap)))
plot(
  NA, xlim = range(wide$year), ylim = range(all_gaps),
  xlab = "Year", ylab = "Gap (actual - synthetic)",
  main = sprintf("In-space placebo, full pool (%d donors): Rwanda vs. all units", length(donors))
)
for (r in placebo_runs) lines(r$res$year, r$res$gap, col = "#9CA3AF", lwd = 1)
lines(rwanda_run$res$year, rwanda_run$res$gap, col = "#DC2626", lwd = 3)
abline(v = treatment_year, lty = 3, lwd = 2, col = "#111827")
abline(h = 0, lty = 1, lwd = 1, col = "#00000055")
legend(
  "bottomleft", legend = c("Rwanda", "Placebo units", "1994 genocide"),
  col = c("#DC2626", "#9CA3AF", "#111827"), lty = c(1, 1, 3), lwd = c(3, 1, 2), bty = "n"
)
mtext(sprintf("Full Sub-Saharan Africa pool (%d donors); Rwanda rank %d of %d, p = %.3f", length(donors), rwanda_rank, nrow(in_space), p_value), side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(lines, collapse = "\n"), "\n")
