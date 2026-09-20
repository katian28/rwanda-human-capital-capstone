#!/usr/bin/env Rscript

# Independent re-estimation of synthetic control donor weights for Rwanda's
# GDP path, using PWT 8.0 rgdpe (see results/replication-validation.md for
# why rgdpe rather than rgdpo is used).
#
# This is an OUTCOME-ONLY synthetic control: donor weights are chosen to
# minimize pre-treatment squared prediction error on the normalized GDP path
# alone (no auxiliary predictor characteristics). This is the fast version of
# independent re-estimation: it answers whether an unconstrained optimizer
# recovers similar donor weights and pre-treatment fit to Hodler's published
# weights. A full covariate-matched replication (PWT 7.1 investment/openness,
# WDI inflation, Polity IV, Freedom House, UCDP conflict, per
# docs/replication-feasibility.md) is a follow-up robustness step, not
# required for this checkpoint.

suppressPackageStartupMessages({
  library(readxl)
  library(quadprog)
})

data_file <- "data/raw/pwt80.xlsx"
data_url <- "https://www.rug.nl/ggdc/docs/pwt80.xlsx"
dir.create(dirname(data_file), recursive = TRUE, showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

if (!file.exists(data_file)) {
  download.file(data_url, data_file, mode = "wb", quiet = TRUE)
}

pwt <- as.data.frame(read_excel(data_file, sheet = "Data"))

published_weights <- c(
  CMR = 0.254, COG = 0.061, GAB = 0.149,
  LBR = 0.032, LSO = 0.192, MLI = 0.016,
  NER = 0.108, SDN = 0.014, SEN = 0.175
)
donors <- names(published_weights)
treatment_year <- 1994
pre_years <- 1970:(treatment_year - 1)
full_years <- 1970:2011
variable <- "rgdpe"

keep <- pwt$countrycode %in% c("RWA", donors) &
  pwt$year %in% full_years
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

pre <- wide[wide$year %in% pre_years, ]
X <- as.matrix(pre[, donors])
y <- pre$RWA

# Minimize ||X w - y||^2 s.t. sum(w) = 1, w >= 0  (quadratic program)
Dmat <- t(X) %*% X
Dmat <- Dmat + diag(1e-8, ncol(Dmat)) # numerical stabilization
dvec <- t(X) %*% y
Amat <- cbind(rep(1, length(donors)), diag(length(donors)))
bvec <- c(1, rep(0, length(donors)))
qp <- solve.QP(Dmat, dvec, Amat, bvec, meq = 1)
estimated_weights <- setNames(pmax(qp$solution, 0), donors)
estimated_weights <- estimated_weights / sum(estimated_weights)

apply_weights <- function(w) {
  vapply(wide$year, function(yr) {
    row <- wide[wide$year == yr, donors]
    sum(w * as.numeric(row))
  }, numeric(1))
}

result <- data.frame(
  year = wide$year,
  actual = wide$RWA,
  synthetic_published = apply_weights(published_weights),
  synthetic_reestimated = apply_weights(estimated_weights)
)
result$gap_published <- result$actual - result$synthetic_published
result$gap_reestimated <- result$actual - result$synthetic_reestimated

write.csv(result, "results/independent-weight-reestimation.csv", row.names = FALSE)

rmspe <- function(gap, years) sqrt(mean(gap[result$year %in% years]^2))
gap_at <- function(col, yr) result[[col]][result$year == yr]

weight_table <- data.frame(
  donor = donors,
  published = round(unname(published_weights[donors]), 3),
  reestimated = round(unname(estimated_weights[donors]), 3)
)

lines <- c(
  "# Independent weight re-estimation",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "## Method",
  "",
  "Outcome-only synthetic control: donor weights (non-negative, summing to 1) are chosen by quadratic programming to minimize squared prediction error on Rwanda's normalized `rgdpe` path over the pre-treatment window (1970-1993). No auxiliary predictor characteristics are used in this pass; see the header of `code/02_reestimate_weights.R` for what a full covariate-matched version would add.",
  "",
  "## Donor weight comparison",
  "",
  "| Donor | Published | Re-estimated |",
  "|-------|-----------|--------------|",
  paste0("| ", weight_table$donor, " | ", sprintf("%.3f", weight_table$published), " | ", sprintf("%.3f", weight_table$reestimated), " |", collapse = "\n"),
  "",
  "## Fit comparison",
  "",
  sprintf("- Pre-treatment RMSPE: published weights %.4f; re-estimated weights %.4f.", rmspe(result$gap_published, pre_years), rmspe(result$gap_reestimated, pre_years)),
  sprintf("- 1994 gap: published weights %.3f; re-estimated weights %.3f.", gap_at("gap_published", 1994), gap_at("gap_reestimated", 1994)),
  sprintf("- 2011 gap: published weights %.3f; re-estimated weights %.3f.", gap_at("gap_published", 2011), gap_at("gap_reestimated", 2011)),
  "",
  "## Interpretation",
  "",
  "An independently optimized donor pool achieves pre-treatment fit at least as good as the published weights by construction (the optimizer minimizes exactly this objective), which is expected and not itself evidence of a stronger result. What matters is whether the *donor composition* is similar and whether the *post-treatment gap* remains close to the published finding under an independent optimization. See the table and 1994/2011 gaps above for that comparison.",
  "",
  "**Not yet done (flagged as follow-up, not required for this checkpoint):** re-estimating with the full predictor set Hodler used (PWT 7.1 investment/openness, WDI inflation, Polity IV, Freedom House political rights, UCDP conflict events, 1985-1990 averages) rather than outcome-only matching."
)
writeLines(lines, "results/independent-weight-reestimation.md")

png("figures/independent-weight-reestimation.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  result$year, result$actual, type = "l", lwd = 3, col = "#111827",
  xlab = "Year", ylab = "Normalized GDP (1991-1993 average = 1)",
  main = "Rwanda GDP: published vs. re-estimated donor weights",
  ylim = range(c(result$actual, result$synthetic_published, result$synthetic_reestimated))
)
lines(result$year, result$synthetic_published, lwd = 3, lty = 2, col = "#2563EB")
lines(result$year, result$synthetic_reestimated, lwd = 3, lty = 4, col = "#059669")
abline(v = treatment_year, lty = 3, lwd = 2, col = "#DC2626")
legend(
  "topleft",
  legend = c("Rwanda", "Synthetic (published weights)", "Synthetic (re-estimated weights)", "1994 genocide"),
  col = c("#111827", "#2563EB", "#059669", "#DC2626"),
  lty = c(1, 2, 4, 3), lwd = c(3, 3, 3, 2), bty = "n", cex = 0.85
)
mtext("PWT 8.0 rgdpe; re-estimated weights from outcome-only QP fit on 1970-1993", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(lines, collapse = "\n"), "\n")
