#!/usr/bin/env Rscript

# Single "show and tell" figure: where does Rwanda rank among all 40 units
# in the full-pool GDP placebo test (code/04), by post/pre RMSPE ratio.
# Log scale because Equatorial Guinea's ratio dwarfs everything else.
# Title is computed from the data, not hardcoded, so it can't silently go
# stale if the underlying numbers change.

results <- read.csv("results/placebo-full-pool-in-space.csv", stringsAsFactors = FALSE)
results <- results[order(-results$ratio), ]
results$rank <- seq_len(nrow(results))

rwanda_rank <- results$rank[results$unit == "RWA"]
n_units <- nrow(results)
p_value <- rwanda_rank / n_units

dir.create("figures", showWarnings = FALSE)
png("figures/placebo-ranking-full-pool.png", width = 1700, height = 1500, res = 170)
par(mar = c(7.0, 6.5, 3.5, 1.5), family = "sans")

cols <- ifelse(results$unit == "RWA", "#DC2626", "#9CA3AF")
bp <- barplot(
  rev(results$ratio), horiz = TRUE, log = "x",
  col = rev(cols), border = NA,
  names.arg = rev(results$unit), las = 1, cex.names = 0.65,
  xlab = "", ylab = "",
  main = sprintf("Rwanda's GDP placebo rank: %d of %d (p = %.2f)", rwanda_rank, n_units, p_value)
)
title(xlab = "Post/pre RMSPE ratio (log scale)", line = 2.6)
abline(v = 1, lty = 3, col = "#00000055")
legend("bottomright", legend = c("Rwanda", "Placebo country"), fill = c("#DC2626", "#9CA3AF"), border = NA, bty = "n", cex = 0.85)
mtext("Full Sub-Saharan Africa donor pool. Rwanda's gap is not an outlier.", side = 1, line = 5.0, cex = 0.75, col = "#4B5563")
dev.off()
cat("Saved figures/placebo-ranking-full-pool.png\n")
cat(sprintf("Rwanda's rank: %d of %d (p = %.3f)\n", rwanda_rank, n_units, p_value))
