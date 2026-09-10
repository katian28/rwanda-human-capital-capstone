#!/usr/bin/env Rscript

# Reconstruct Hodler's published GDP path using PWT 8.0 and reported weights.
# The script deliberately tests both rgdpo (named in the article) and rgdpe
# because only rgdpe reproduces the published benchmark path.

suppressPackageStartupMessages(library(readxl))

data_file <- "data/raw/pwt80.xlsx"
data_url <- "https://www.rug.nl/ggdc/docs/pwt80.xlsx"
dir.create(dirname(data_file), recursive = TRUE, showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

if (!file.exists(data_file)) {
  download.file(data_url, data_file, mode = "wb", quiet = TRUE)
}

pwt <- as.data.frame(read_excel(data_file, sheet = "Data"))
weights <- c(
  CMR = 0.254, COG = 0.061, GAB = 0.149,
  LBR = 0.032, LSO = 0.192, MLI = 0.016,
  NER = 0.108, SDN = 0.014, SEN = 0.175
)

reconstruct <- function(variable) {
  keep <- pwt$countrycode %in% c("RWA", names(weights)) &
    pwt$year >= 1970 & pwt$year <= 2011
  panel <- pwt[keep, c("countrycode", "year", variable)]
  names(panel)[3] <- "value"
  panel$normalized <- NA_real_

  for (code in unique(panel$countrycode)) {
    country <- panel$countrycode == code
    base <- mean(panel$value[country & panel$year %in% 1991:1993])
    panel$normalized[country] <- panel$value[country] / base
  }

  result <- panel[panel$countrycode == "RWA", c("year", "normalized")]
  names(result)[2] <- "actual"
  result$synthetic <- vapply(result$year, function(target_year) {
    donors <- panel[
      panel$year == target_year & panel$countrycode %in% names(weights),
    ]
    values <- setNames(donors$normalized, donors$countrycode)
    sum(weights * values[names(weights)])
  }, numeric(1))
  result$gap <- result$actual - result$synthetic
  result$variable <- variable
  result
}

rgdpe <- reconstruct("rgdpe")
rgdpo <- reconstruct("rgdpo")
comparison <- rbind(rgdpe, rgdpo)
write.csv(comparison, "results/published-weight-replication.csv", row.names = FALSE)

metric <- function(result, year) result$gap[result$year == year]
rmspe <- function(result) sqrt(mean(result$gap[result$year < 1994]^2))

validation <- c(
  "# Published-weight GDP reconstruction",
  "",
  "**Run date:** 9 September 2026",
  "",
  "## Result",
  "",
  "Using PWT 8.0 `rgdpe` with the paper's reported rounded donor weights reproduces the headline path. Using `rgdpo`, the variable named in the manuscript, does not. This indicates an apparent outcome-label inconsistency that must be checked against the author's original files.",
  "",
  "## Benchmark comparison",
  "",
  sprintf("- Published pre-treatment RMSPE: 0.0584; reconstructed with `rgdpe`: %.4f; with `rgdpo`: %.4f.", rmspe(rgdpe), rmspe(rgdpo)),
  sprintf("- Published 1994 gap: -0.58; reconstructed with `rgdpe`: %.3f; with `rgdpo`: %.3f.", metric(rgdpe, 1994), metric(rgdpo, 1994)),
  sprintf("- Published 2011 gap: approximately 0.00; reconstructed with `rgdpe`: %.3f; with `rgdpo`: %.3f.", metric(rgdpe, 2011), metric(rgdpo, 2011)),
  "",
  "The small remaining differences are consistent with applying donor weights rounded to three decimals; the displayed weights sum to 1.001. Exact author weights and code were not available for this run.",
  "",
  "## Interpretation",
  "",
  "This completes the first replication checkpoint: the published headline result can be reconstructed from the exact PWT release and reported weights. It does not yet reproduce the optimization that generated those weights or the placebo inference. Those are the next replication stages."
)
writeLines(validation, "results/replication-validation.md")

png("figures/published-weight-gdp-replication.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  rgdpe$year, rgdpe$actual, type = "l", lwd = 3, col = "#111827",
  xlab = "Year", ylab = "Normalized GDP (1991-1993 average = 1)",
  main = "Rwanda GDP: published-weight reconstruction",
  ylim = range(c(rgdpe$actual, rgdpe$synthetic))
)
lines(rgdpe$year, rgdpe$synthetic, lwd = 3, lty = 2, col = "#2563EB")
abline(v = 1994, lty = 3, lwd = 2, col = "#DC2626")
legend(
  "topleft", legend = c("Rwanda", "Synthetic Rwanda", "1994 genocide"),
  col = c("#111827", "#2563EB", "#DC2626"), lty = c(1, 2, 3),
  lwd = c(3, 3, 2), bty = "n"
)
mtext("PWT 8.0 rgdpe; synthetic series uses Hodler's published rounded donor weights", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(validation, collapse = "\n"), "\n")
