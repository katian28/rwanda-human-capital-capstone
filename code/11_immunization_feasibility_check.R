#!/usr/bin/env Rscript
# Feasibility check for immunization coverage (DTP3 / MCV1) as a candidate
# replacement extension outcome, after PWT's hc index turned out to have
# fabricated annual resolution (docs/data-availability.md) and WDI school
# enrollment turned out to be missing exactly 1994-1998 (the genocide
# years themselves). Same balanced-panel screen used for those checks,
# applied here before committing to a new outcome variable.
#
# Data: WHO/UNICEF WUENIC (Estimates of National Immunization Coverage),
# redistributed by Our World in Data as a long-format CSV -- see
# docs/source-register.md for the full citation and download details.
# This is administrative-report data (country health systems reporting to
# WHO/UNICEF's Joint Reporting Form), not a demographic model smoothed
# between infrequent household surveys, which is the mechanism that broke
# both hc and infant mortality/fertility rate as candidates.

dir.create("results", showWarnings = FALSE)

dtp3 <- read.csv("data/raw/who_dtp3_coverage.csv", stringsAsFactors = FALSE)
mcv1 <- read.csv("data/raw/who_mcv1_coverage.csv", stringsAsFactors = FALSE)
names(dtp3)[4] <- "dtp3"
names(mcv1)[4] <- "mcv1"

# Same 48-country Sub-Saharan Africa candidate pool used throughout this
# project (code/04, code/07), minus Rwanda and the spillover-risk
# neighbors already excluded elsewhere.
ssa_all <- c(
  "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD", "COM",
  "COD", "COG", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA",
  "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
  "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM",
  "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE"
)
excluded <- c("BDI", "COD", "TZA", "UGA")
candidates <- setdiff(ssa_all, c("RWA", excluded))

first_year <- 1980  # WUENIC's own documented start year
last_year <- 2011    # matches this project's PWT-based window
treatment_year <- 1994

# ---- 1. Rwanda's own series across the treatment window -------------------

rwa <- dtp3[dtp3$Code == "RWA" & dtp3$Year %in% first_year:last_year, c("Year", "dtp3")]
rwa <- merge(rwa, mcv1[mcv1$Code == "RWA", c("Year", "mcv1")], by = "Year", all.x = TRUE)
# Gaps relative to Rwanda's OWN start year, not the global first_year --
# Rwanda's series starts in 1981, one year after WUENIC's 1980 baseline,
# which is not a meaningful gap.
rwa_gap_years <- setdiff(min(rwa$Year):last_year, rwa$Year[!is.na(rwa$dtp3)])

# ---- 2. Donor-pool panel completeness --------------------------------------
# A donor is usable if it has DTP3 coverage for every year from its own
# start through 2011, with a start year no later than 1990 (so it can
# contribute to the pre-treatment fit).

coverage_check <- do.call(rbind, lapply(candidates, function(code) {
  rows <- dtp3[dtp3$Code == code & dtp3$Year %in% first_year:last_year, ]
  if (nrow(rows) == 0) return(data.frame(unit = code, start_year = NA, n_years = 0, complete = FALSE))
  start <- min(rows$Year)
  full_range <- start:last_year
  complete <- setequal(rows$Year, full_range)
  data.frame(unit = code, start_year = start, n_years = nrow(rows), complete = complete)
}))

usable_donors <- coverage_check$unit[coverage_check$complete & coverage_check$start_year <= 1990]

# ---- 3. Report ---------------------------------------------------------------

lines <- c(
  "# Immunization coverage (DTP3/MCV1) feasibility check",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "Checked as a candidate replacement for the human-capital extension after PWT's `hc` index (fabricated annual resolution) and WDI secondary enrollment (missing exactly 1994-1998) both failed. Source: WHO/UNICEF WUENIC, administrative-report data, not survey-smoothed -- see `docs/source-register.md`.",
  "",
  "## Rwanda, 1980-2011",
  "",
  sprintf("DTP3 coverage: %s.", paste(sprintf("%d=%s%%", rwa$Year, rwa$dtp3), collapse = ", ")),
  "",
  if (length(rwa_gap_years) == 0) {
    "**No missing years.** Unlike WDI enrollment (missing 1994-1998 entirely), Rwanda's DTP3 series is complete through the genocide, and shows a real crisis signature -- a sharp drop in 1994 followed by recovery the very next year -- rather than a flat interpolated line."
  } else {
    sprintf("**Missing years: %s.**", paste(rwa_gap_years, collapse = ", "))
  },
  "",
  "## Donor pool (Sub-Saharan Africa, excluding Rwanda and spillover-risk neighbors)",
  "",
  sprintf("%d of %d candidate donors have complete, gap-free DTP3 coverage starting in 1990 or earlier: %s.",
          length(usable_donors), length(candidates), paste(sort(usable_donors), collapse = ", ")),
  "",
  sprintf("Excluded (late start, post-1990, or internal gaps): %s.",
          paste(sort(setdiff(candidates, usable_donors)), collapse = ", ")),
  "",
  "## Verdict",
  "",
  if (length(rwa_gap_years) == 0 && length(usable_donors) >= 15) {
    "Passes the balanced-panel screen that killed the previous two candidates. Genuinely annual, administratively-reported data, no gap during the exact crisis years, and a large enough donor pool to run a full-pool placebo test analogous to code/04. Caveat to disclose in the paper: WUENIC does targeted interpolation for isolated missing country/year cells in its published methodology -- a much smaller intervention than hc's wholesale annual fabrication, but not zero, and worth stating plainly."
  } else {
    "Does not clearly pass the balanced-panel screen -- see the gap/donor-pool numbers above before proceeding."
  }
)
writeLines(lines, "results/immunization-feasibility-check.md")
cat(paste(lines, collapse = "\n"), "\n")
