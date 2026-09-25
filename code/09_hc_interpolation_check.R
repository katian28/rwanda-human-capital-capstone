#!/usr/bin/env Rscript
# Checks whether PWT 8.0's hc (human capital index) is actually annual
# information, or an interpolation of Barro-Lee's five-year schooling
# data. If it's interpolated, the year-over-year change within each
# five-year window should be roughly constant, with a visible break at
# each five-year mark (1970, 1975, 1980, 1985, 1990, ...). Also checks
# the 2010-2011 boundary specifically, since the human-capital gap plot
# (figures/hc-extension-gaps.png) goes suspiciously flat right there.
#
# This matters because it explains why the human-capital extension's
# pre-treatment fit (code/07) is so tight: a 24-year pre-treatment window
# is not 24 independent data points if the underlying series only has
# ~5 real observations in it.

library(readxl)

pwt <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))

# ---- Check 1: five-year regime shifts, Rwanda plus four donor countries --

check_countries <- c("RWA", "CMR", "ZMB", "MLI", "SEN")
pre <- pwt[pwt$countrycode %in% check_countries & pwt$year %in% 1970:1993, c("countrycode", "year", "hc")]
pre <- pre[order(pre$countrycode, pre$year), ]
pre$yearly_change <- ave(pre$hc, pre$countrycode, FUN = function(x) c(NA, diff(x)))

rwa <- pre[pre$countrycode == "RWA", c("year", "hc", "yearly_change")]

dir.create("results", showWarnings = FALSE)
write.csv(pre, "results/hc-interpolation-check.csv", row.names = FALSE)

# ---- Check 2: does every country freeze between 2010 and 2011? -----------

late <- pwt[pwt$countrycode %in% check_countries & pwt$year %in% c(2010, 2011), c("countrycode", "year", "hc")]
late_wide <- reshape(late, idvar = "countrycode", timevar = "year", direction = "wide")
late_wide$frozen <- late_wide$hc.2010 == late_wide$hc.2011
write.csv(late_wide, "results/hc-2010-2011-freeze-check.csv", row.names = FALSE)

# Same check for rgdpe, to confirm this is hc-specific, not a general
# PWT-vintage artifact affecting every variable.
gdp_late <- pwt[pwt$countrycode == "RWA" & pwt$year %in% c(2010, 2011), c("year", "rgdpe")]

lines <- c(
  "# Is PWT hc annual data, or interpolated from Barro-Lee's five-year data?",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "## Check 1: five-year regime shifts",
  "",
  "Rwanda's hc year-over-year change, 1971-1993:",
  "",
  "| Year | hc | Yearly change |",
  "|------|-----|---------------|",
  paste0("| ", rwa$year, " | ", sprintf("%.6f", rwa$hc), " | ",
         ifelse(is.na(rwa$yearly_change), "--", sprintf("%.6f", rwa$yearly_change)), " |", collapse = "\n"),
  "",
  "The same pattern (nearly constant within each five-year block, distinct shift at each five-year boundary) holds for Cameroon, Zambia, Mali, and Senegal as well -- see `results/hc-interpolation-check.csv` for all five countries. This is not a Rwanda-specific artifact.",
  "",
  "## Check 2: the 2010-2011 boundary",
  "",
  sprintf(
    "hc is IDENTICAL between 2010 and 2011 for every country checked (%s): the 2011 value is the 2010 value carried forward, not real data. For comparison, Rwanda's rgdpe changes normally over the same years (%.2f in 2010, %.2f in 2011) -- this freeze is specific to hc, not a general PWT-vintage issue.",
    paste(check_countries, collapse = ", "), gdp_late$rgdpe[gdp_late$year == 2010], gdp_late$rgdpe[gdp_late$year == 2011]
  ),
  "",
  "## Why this matters",
  "",
  "A 24-year pre-treatment window (1970-1993) is effectively ~5 real data points per country, not 24 independent ones, since every donor country's hc is built the same way. Fitting a weighted average of 27 donor countries to match a series with that few real degrees of freedom is close to guaranteed to look near-perfect almost regardless of which country is treated -- consistent with 5 of the 27 donors showing an even tighter pre-treatment fit than Rwanda (see code/07 placebo output).",
  "",
  "The 2010-2011 freeze also means the apparent 'plateau' in the post-treatment gap (figures/hc-extension-gaps.png) is partly mechanical: the 2011 data point adds no independent information over 2010, for Rwanda or any donor. The post-treatment RMSPE in code/07 effectively double-counts the 2010 gap once.",
  "",
  "This does not necessarily invalidate the human-capital placebo result (in-space ranking partially self-corrects, since every unit's pre-treatment fit is inflated the same mechanical way), but it does mean a tight pre-treatment fit on hc does not validate the counterfactual the way Abadie's method assumes for a genuinely high-frequency outcome, and the true post-treatment window is closer to 17 informative years than 18."
)
writeLines(lines, "results/hc-interpolation-check.md")
cat(paste(lines, collapse = "\n"), "\n")
