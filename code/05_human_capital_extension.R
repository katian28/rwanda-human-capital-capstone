#!/usr/bin/env Rscript

# Human-capital extension: does Rwanda's PWT 8.0 human-capital index (hc)
# show a gap after 1994 the way GDP does?
#
# Donor pool: same Sub-Saharan Africa construction as
# code/04_placebo_full_pool.R (43 candidates, minus Burundi/DRC/Tanzania/
# Uganda for spillover risk), screened here for complete `hc` coverage
# instead of `rgdpe`, matching docs/data-availability.md's "27 eligible
# donors" figure.
#
# Method: outcome-only synthetic control (same as code/02 and code/03),
# for consistency with how the GDP replication and placebo tests were done.
# Includes an in-space placebo test from the start, because the GDP result
# (code/04) showed that a point estimate without a full-pool placebo test
# overstates how unusual a gap looks.
#
# This replaces the hc numbers a different, code-less session wrote
# directly into the paper's Section 4 (it fetched PWT 8.0 itself with no
# access to this repo and flagged its own numbers as needing cross-check).

suppressPackageStartupMessages({
  library(readxl)
  library(quadprog)
})

data_file <- "data/raw/pwt80.xlsx"
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)
stopifnot(file.exists(data_file))

pwt <- as.data.frame(read_excel(data_file, sheet = "Data"))

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
variable <- "hc"

coverage <- pwt[pwt$countrycode %in% candidates & pwt$year %in% full_years, c("countrycode", "year", variable)]
complete_counts <- tapply(!is.na(coverage[[variable]]), coverage$countrycode, sum)
eligible <- names(complete_counts)[complete_counts == length(full_years)]
dropped <- setdiff(candidates, eligible)

cat(sprintf("Candidates: %d. Eligible (complete hc %d-%d): %d. Dropped for missingness: %s\n",
  length(candidates), min(full_years), max(full_years), length(eligible), paste(dropped, collapse = ", ")))

donors <- sort(eligible)

keep <- pwt$countrycode %in% c("RWA", donors) & pwt$year %in% full_years
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

# ---- Main extension result ----------------------------------------------

rwanda_run <- run_unit("RWA", donors)
write.csv(rwanda_run$res, "results/human-capital-extension.csv", row.names = FALSE)

top_weights <- sort(rwanda_run$weights[rwanda_run$weights > 0.01], decreasing = TRUE)
weight_table <- data.frame(donor = names(top_weights), weight = round(unname(top_weights), 3))

post_gap <- rwanda_run$res$gap[rwanda_run$res$year %in% post_years]
post_years_vec <- rwanda_run$res$year[rwanda_run$res$year %in% post_years]
peak_idx <- which.max(abs(post_gap))

# ---- In-space placebo (full pool, same as code/04) -----------------------

cat("Fitting placebo units for hc (", length(donors), "donors)...\n")
placebo_runs <- lapply(donors, function(d) run_unit(d, setdiff(donors, d)))
in_space <- do.call(rbind, lapply(c(list(rwanda_run), placebo_runs), function(r) {
  data.frame(unit = r$unit, pre_rmspe = r$pre_rmspe, post_rmspe = r$post_rmspe, ratio = r$ratio)
}))
in_space <- in_space[order(-in_space$ratio), ]
in_space$rank <- seq_len(nrow(in_space))
rwanda_rank <- in_space$rank[in_space$unit == "RWA"]
p_value <- rwanda_rank / nrow(in_space)
write.csv(in_space, "results/human-capital-placebo-in-space.csv", row.names = FALSE)

# ---- Report ---------------------------------------------------------------

lines <- c(
  "# Human-capital extension (PWT 8.0 `hc`)",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "## Donor pool",
  "",
  sprintf("Same Sub-Saharan Africa construction as `code/04_placebo_full_pool.R` (%d candidates), screened for complete `hc` coverage 1970-2011 instead of `rgdpe`: %d eligible donors.", length(candidates), length(donors)),
  sprintf("Dropped for incomplete `hc` coverage: %s.", paste(dropped, collapse = ", ")),
  "",
  "## Main result",
  "",
  sprintf("Pre-treatment RMSPE: %.4f.", rwanda_run$pre_rmspe),
  sprintf("Post-treatment (1994-2011) average gap: %.3f. Largest-magnitude gap: %.3f in %d.", mean(post_gap), post_gap[peak_idx], post_years_vec[peak_idx]),
  sprintf("Direction: %s.", if (mean(post_gap) > 0) "Rwanda's human-capital index sits ABOVE its synthetic counterfactual after 1994 -- no genocide-era shock visible in this index." else "Rwanda's human-capital index sits BELOW its synthetic counterfactual after 1994, consistent with a shock."),
  "",
  "**Donor weights (>1%):**",
  "",
  "| Donor | Weight |",
  "|-------|--------|",
  paste0("| ", weight_table$donor, " | ", sprintf("%.3f", weight_table$weight), " |", collapse = "\n"),
  "",
  "## In-space placebo",
  "",
  sprintf("Rwanda's rank: %d of %d (p = %.3f).", rwanda_rank, nrow(in_space), p_value),
  if (p_value <= 0.10) {
    "This clears the conventional 10% rank-based placebo threshold."
  } else {
    "This does NOT clear the conventional 10% rank-based placebo threshold -- consistent with the main result showing no clear post-1994 shock in this index."
  },
  "",
  "## Interpretation",
  "",
  "The PWT human-capital index is a smoothed, constructed measure built from schooling and assumed returns (see `docs/data-availability.md`). A flat or positive post-1994 gap here is consistent with two different stories that this design cannot distinguish: (a) Rwanda's human capital did not suffer a comparable shock to its GDP, or (b) the index is too smoothed/slow-moving to register a shock of this kind. This ambiguity should be stated as a limitation, not resolved by assumption.",
  "",
  "**Supersedes:** the hc numbers a prior session wrote into the paper's Section 4 without access to this repo's code or data pipeline (see doc comment thread, 2026-09-19). Use these numbers instead."
)
writeLines(lines, "results/human-capital-extension.md")

png("figures/human-capital-extension.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  rwanda_run$res$year, rwanda_run$res$actual, type = "l", lwd = 3, col = "#111827",
  xlab = "Year", ylab = "Normalized human-capital index (1991-1993 average = 1)",
  main = "Rwanda human capital (PWT 8.0 hc): actual vs. synthetic",
  ylim = range(c(rwanda_run$res$actual, rwanda_run$res$synthetic))
)
lines(rwanda_run$res$year, rwanda_run$res$synthetic, lwd = 3, lty = 2, col = "#2563EB")
abline(v = treatment_year, lty = 3, lwd = 2, col = "#DC2626")
legend(
  "topleft", legend = c("Rwanda", "Synthetic Rwanda", "1994 genocide"),
  col = c("#111827", "#2563EB", "#DC2626"), lty = c(1, 2, 3), lwd = c(3, 3, 2), bty = "n"
)
mtext(sprintf("PWT 8.0 hc; %d-donor outcome-only synthetic control; placebo rank %d of %d (p=%.2f)", length(donors), rwanda_rank, nrow(in_space), p_value), side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(lines, collapse = "\n"), "\n")
