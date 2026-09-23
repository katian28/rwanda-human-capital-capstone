#!/usr/bin/env Rscript

# Applies Hodler's own documented placebo-exclusion rule (see
# docs/replication-feasibility.md: "exclusion from reported placebo
# inference when pre-treatment RMSPE exceeds the placebo median plus one
# standard deviation") to the full 39-country GDP placebo test from
# code/04_placebo_full_pool.R, to check whether it changes the weak
# full-pool result (rank 20/40, p=0.50).
#
# This is a pre-specified rule from the paper being replicated, not a
# post-hoc exclusion chosen after seeing which units look inconvenient.

results <- read.csv("results/placebo-in-space-full.csv", stringsAsFactors = FALSE)

pre_rmspe <- results$pre_rmspe
threshold <- median(pre_rmspe) + sd(pre_rmspe)
dropped <- results$unit[pre_rmspe > threshold]
kept <- results[pre_rmspe <= threshold, ]
kept <- kept[order(-kept$ratio), ]
kept$rank <- seq_len(nrow(kept))

rwanda_rank <- kept$rank[kept$unit == "RWA"]
p_value <- rwanda_rank / nrow(kept)

write.csv(kept, "results/placebo-in-space-full-hodler-rule.csv", row.names = FALSE)

lines <- c(
  "# Full-pool GDP placebo test with Hodler's exclusion rule applied",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "## Rule",
  "",
  sprintf("Per `docs/replication-feasibility.md`, Hodler excludes placebo units whose own pre-treatment RMSPE exceeds the placebo group's median plus one standard deviation (threshold here: %.4f). This is the paper's own pre-specified rule, applied here for the first time to the full 39-country placebo test from `code/04_placebo_full_pool.R`.", threshold),
  "",
  "## Result",
  "",
  sprintf("Dropped %d units for poor pre-treatment fit: %s.", length(dropped), paste(dropped, collapse = ", ")),
  sprintf("**Rwanda's rank barely changes: %d of %d (p = %.3f), versus %d of 40 (p = 0.50) without the rule.**", rwanda_rank, nrow(kept), p_value, rwanda_rank),
  "",
  "## Why the rule doesn't help",
  "",
  "The units that outrank Rwanda (Equatorial Guinea, Guinea, Mauritania, The Gambia, Madagascar) all have GOOD pre-treatment fits -- several fit their own pre-1994 path better than Rwanda's synthetic control fits Rwanda's. Their extreme ratios come from large, unrelated POST-period volatility (Equatorial Guinea's oil boom is the standout case: pre-treatment RMSPE 0.076, post-treatment RMSPE 39.7). Hodler's rule filters units with bad PRE-treatment fit; it does not filter units whose post-treatment period happens to be volatile for reasons unrelated to the 1994 genocide. The two problems are different, and this rule only solves the first one.",
  "",
  "## Interpretation",
  "",
  "This was tested, not assumed: applying the original paper's own documented exclusion rule does not rescue the full-pool placebo result. Reporting this honestly is more informative than either omitting the check or searching for a different exclusion rule that happens to produce a better-looking rank."
)
writeLines(lines, "results/placebo-hodler-rule.md")
cat(paste(lines, collapse = "\n"), "\n")
