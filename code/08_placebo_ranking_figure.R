#!/usr/bin/env Rscript

# Single "show and tell" figure: where does Rwanda rank among all 40 units
# in the full-pool GDP placebo test, by post/pre RMSPE ratio. Log scale
# because Equatorial Guinea's ratio (525) dwarfs everything else.

results <- read.csv("results/placebo-in-space-full.csv", stringsAsFactors = FALSE)
results <- results[order(-results$ratio), ]
results$rank <- seq_len(nrow(results))

dir.create("figures", showWarnings = FALSE)
png("figures/placebo-ranking-full-pool.png", width = 1700, height = 1500, res = 170)
par(mar = c(7.0, 6.5, 3.5, 1.5), family = "sans")

cols <- ifelse(results$unit == "RWA", "#DC2626", "#9CA3AF")
bp <- barplot(
  rev(results$ratio), horiz = TRUE, log = "x",
  col = rev(cols), border = NA,
  names.arg = rev(results$unit), las = 1, cex.names = 0.65,
  xlab = "", ylab = "",
  main = "Rwanda's GDP placebo rank: 20th of 40 (p = 0.50)"
)
title(xlab = "Post/pre RMSPE ratio (log scale)", line = 2.6)
abline(v = 1, lty = 3, col = "#00000055")
legend("bottomright", legend = c("Rwanda", "Placebo country"), fill = c("#DC2626", "#9CA3AF"), border = NA, bty = "n", cex = 0.85)
mtext("Full Sub-Saharan Africa donor pool. Rwanda's gap is not an outlier: half the comparison group ranks higher.", side = 1, line = 5.0, cex = 0.75, col = "#4B5563")
dev.off()
cat("Saved figures/placebo-ranking-full-pool.png\n")
