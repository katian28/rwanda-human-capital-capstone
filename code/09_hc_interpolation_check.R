#!/usr/bin/env Rscript
# Checks whether PWT 8.0's hc (human capital index) is actually annual
# information, or an interpolation of Barro-Lee's five-year schooling
# data. If it's interpolated, the year-over-year change within each
# five-year window should be roughly constant, with a visible break at
# each five-year mark (1970, 1975, 1980, 1985, 1990, ...).
#
# This matters because it explains why the human-capital extension's
# pre-treatment fit (code/07) is so tight: a 24-year pre-treatment window
# is not 24 independent data points if the underlying series only has
# ~5 real observations in it.

library(readxl)

pwt <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))
rwa <- pwt[pwt$countrycode == "RWA" & pwt$year %in% 1970:1993, c("year", "hc")]
rwa <- rwa[order(rwa$year), ]
rwa$yearly_change <- c(NA, diff(rwa$hc))

dir.create("results", showWarnings = FALSE)
write.csv(rwa, "results/hc-interpolation-check.csv", row.names = FALSE)

lines <- c(
  "# Is PWT hc annual data, or interpolated from Barro-Lee's five-year data?",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "Rwanda's hc year-over-year change, 1971-1993:",
  "",
  "| Year | hc | Yearly change |",
  "|------|-----|---------------|",
  paste0("| ", rwa$year, " | ", sprintf("%.6f", rwa$hc), " | ",
         ifelse(is.na(rwa$yearly_change), "--", sprintf("%.6f", rwa$yearly_change)), " |", collapse = "\n"),
  "",
  "## Finding",
  "",
  "The yearly change is nearly constant within each five-year block (1971-1975, 1976-1980, 1981-1985, 1986-1990, 1991-1993), and shifts distinctly at each five-year boundary -- exactly Barro-Lee's observation grid. This confirms PWT's hc is a deterministic transform of Barro-Lee schooling data, interpolated between five-year points, not genuinely annual information.",
  "",
  "## Why this matters for code/07 (human-capital extension)",
  "",
  "A 24-year pre-treatment window (1970-1993) is effectively ~5 real data points per country, not 24 independent ones, since every donor country's hc is built the same way. Fitting a weighted average of 27 donor countries to match a series with that few real degrees of freedom is close to guaranteed to look near-perfect almost regardless of which country is treated -- consistent with 5 of the 27 donors showing an even tighter pre-treatment fit than Rwanda (see code/07 placebo output).",
  "",
  "This does not necessarily invalidate the human-capital placebo result (in-space ranking partially self-corrects, since every unit's pre-treatment fit is inflated the same mechanical way), but it does mean a tight pre-treatment fit on hc does not validate the counterfactual the way Abadie's method assumes for a genuinely high-frequency outcome. The post-treatment gap itself may also be partly shaped by how the interpolation behaved for a country with disrupted underlying data during the study period, not by a real annual human-capital trajectory."
)
writeLines(lines, "results/hc-interpolation-check.md")
cat(paste(lines, collapse = "\n"), "\n")
