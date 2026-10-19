#!/usr/bin/env Rscript
# Checks whether Hodler's actual predictor set (PWT 8.0 human capital,
# PWT 7.1 investment/openness, WDI GDP-deflator inflation, Polity
# political regime, Freedom House political rights, UCDP conflict -- all
# seven confirmed directly against the manuscript PDF, see docs/
# paper-facts-replication.md) can actually be assembled for the donors
# that matter. Two donor sets checked: Hodler's own 9 non-zero-weight
# donors (the minimum that must work), and the project's full Sub-Saharan
# Africa candidate pool (43 countries once Rwanda and the four
# spillover-risk neighbors are removed from the 48-country SSA list below
# -- computed, not hardcoded, since an earlier version of this comment
# just said "39" and went stale).
#
# The STRICT check below (every year in-window present, no na.rm
# averaging) also answers a second question: Hodler's own placebo pool is
# 22 countries (confirmed directly from the manuscript, Figure 1: "D: 1,
# N: 22"), far smaller than this project's lenient-completeness pool. The
# strict count here is the test of whether requiring full-window
# completeness -- not a different candidate list -- is what explains the
# gap.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
})

hodler9 <- c("CMR", "COG", "GAB", "LBR", "LSO", "MLI", "NER", "SDN", "SEN")
ssa_all <- c(
  "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD", "COM",
  "COD", "COG", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA",
  "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
  "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM",
  "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE"
)
excluded <- c("BDI", "COD", "TZA", "UGA")
full_pool <- setdiff(ssa_all, c("RWA", excluded))
pre_window <- 1985:1990   # Hodler's standard predictor-averaging window
conflict_window <- 1991:1993  # Hodler's conflict-specific window

# ---- 0. PWT 8.0 human capital (hc) -----------------------------------------
# Confirmed in the manuscript (p.7): "The human capital index from PWT
# 8.0, which is based on years of schooling and an estimate of the rate
# of return." Same file as the GDP outcome itself (pwt80.xlsx).

pwt80 <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))

# ---- 1. PWT 7.1: investment share (ki), openness (openk) ------------------
# COD is coded ZAR in this vintage; SSD doesn't exist; ERI has almost no data.

pwt71 <- read.csv("data/raw/pwt71.csv", stringsAsFactors = FALSE)
pwt71$isocode[pwt71$isocode == "ZAR"] <- "COD"  # remap to this project's convention

check_coverage <- function(df, code_col, year_col, value_col, codes, years, label) {
  out <- sapply(codes, function(cc) {
    sub <- df[df[[code_col]] == cc & df[[year_col]] %in% years, value_col]
    sum(!is.na(sub)) == length(years)
  })
  cat(sprintf("%-10s complete for %2d of %2d: %s\n", label, sum(out), length(codes),
              paste(codes[!out], collapse = ", ")))
  out
}

# Looser bar: at least one real observation in the window, so the special
# predictor's mean() can be computed with na.rm=TRUE over whatever years
# exist -- standard practice, and plausibly what Hodler himself did rather
# than requiring literal full-window completeness.
check_any <- function(df, code_col, year_col, value_col, codes, years, label) {
  out <- sapply(codes, function(cc) {
    sub <- df[df[[code_col]] == cc & df[[year_col]] %in% years, value_col]
    sum(!is.na(sub)) >= 1
  })
  cat(sprintf("%-10s has >=1 obs for %2d of %2d: %s\n", label, sum(out), length(codes),
              paste(codes[!out], collapse = ", ")))
  out
}

cat("=== PWT 8.0 human capital (hc), 1985-1990 ===\n")
hc_9 <- check_coverage(pwt80, "countrycode", "year", "hc", hodler9, pre_window, "Hodler-9")
hc_full <- check_coverage(pwt80, "countrycode", "year", "hc", full_pool, pre_window, "Full-pool")

cat("\n=== PWT 7.1 investment share (ki), 1985-1990 ===\n")
pwt_ki_9 <- check_coverage(pwt71, "isocode", "year", "ki", hodler9, pre_window, "Hodler-9")
pwt_ki_39 <- check_coverage(pwt71, "isocode", "year", "ki", full_pool, pre_window, "Full-pool")

cat("\n=== PWT 7.1 openness (openk), 1985-1990 ===\n")
pwt_openk_9 <- check_coverage(pwt71, "isocode", "year", "openk", hodler9, pre_window, "Hodler-9")
pwt_openk_39 <- check_coverage(pwt71, "isocode", "year", "openk", full_pool, pre_window, "Full-pool")

# ---- 2. WDI GDP-deflator inflation ------------------------------------------
# Confirmed in the manuscript (p.7): "inflation defined as the annual
# change in the GDP deflator from WDI" -- not CPI. An earlier version of
# this check used WDI CPI, which is what originally made this project
# think Liberia and much of the full candidate pool had to be dropped;
# the deflator does not have that problem (see docs/source-register.md).

wdi <- read.csv("data/raw/wdi_inflation_deflator.csv", stringsAsFactors = FALSE)

cat("\n=== WDI GDP-deflator inflation, 1985-1990 ===\n")
wdi_9 <- check_coverage(wdi, "countrycode", "year", "inflation_deflator_pct", hodler9, pre_window, "Hodler-9")
wdi_39 <- check_coverage(wdi, "countrycode", "year", "inflation_deflator_pct", full_pool, pre_window, "Full-pool")

# ---- 3. Polity5 political regime (polity2) ---------------------------------

polity <- read_excel("data/raw/polity.xls")
polity <- as.data.frame(polity)
# Polity's scode does NOT match ISO3 for many countries -- verified by
# checking every SSA country's actual (scode, country, year-range) triple
# directly rather than assuming. For Ethiopia and Sudan specifically,
# Polity splits the pre/post-independence (Eritrea 1993, South Sudan 2011)
# periods into separate scodes; ETH/SUD (not ETI/SDN) are the ones
# covering this project's 1985-1990 predictor window.
scode_to_iso3 <- c(
  ANG = "AGO", BEN = "BEN", BOT = "BWA", BFO = "BFA", BUI = "BDI",
  CAO = "CMR", CAP = "CPV", CEN = "CAF", CHA = "TCD", COM = "COM",
  CON = "COG", ZAI = "COD", IVO = "CIV", EQG = "GNQ", ERI = "ERI",
  SWA = "SWZ", ETH = "ETH", GAB = "GAB", GAM = "GMB", GHA = "GHA",
  GUI = "GIN", GNB = "GNB", KEN = "KEN", LES = "LSO", LBR = "LBR",
  MAG = "MDG", MAW = "MWI", MLI = "MLI", MAA = "MRT", MAS = "MUS",
  MZM = "MOZ", NAM = "NAM", NIR = "NER", NIG = "NGA", RWA = "RWA",
  SAO = "STP", SEN = "SEN", SEY = "SYC", SIE = "SLE", SOM = "SOM",
  SAF = "ZAF", SSU = "SSD", SUD = "SDN", TAZ = "TZA", TOG = "TGO",
  UGA = "UGA", ZAM = "ZMB", ZIM = "ZWE"
)
polity$scode <- ifelse(polity$scode %in% names(scode_to_iso3),
                        scode_to_iso3[polity$scode], polity$scode)

cat("\n=== Polity5 polity2, 1985-1990 ===\n")
pol_9 <- check_coverage(polity, "scode", "year", "polity2", hodler9, pre_window, "Hodler-9")
pol_39 <- check_coverage(polity, "scode", "year", "polity2", full_pool, pre_window, "Full-pool")

# ---- 4. Freedom House political rights (PR) --------------------------------
# Wide format: triplets of (PR, CL, Status) columns per survey edition. Two
# distinct year-labeling regimes, confirmed by inspecting the raw headers:
#   - From the "1990-91" edition onward, "Year(s) Under Review" is already a
#     clean single calendar year (e.g. "1990") -- use it directly.
#   - Before that (1973-1989), editions span irregular, overlapping
#     multi-month ranges (e.g. "Nov.1987-Nov.1988") with no clean single
#     year in that field. The "Survey Edition" row's LAST number (e.g. "84"
#     in "1983-84"), expanded to a full year and minus 1, gives a clean,
#     non-overlapping, gap-free run of consecutive years across the entire
#     1973-1989 stretch that connects seamlessly to the 1990-91 edition's
#     clean "1990" (verified directly against the header row: using the
#     FIRST number instead leaves 1989 completely unassigned, a one-year
#     gap, which is wrong -- there is no missing year in the underlying
#     editions, only in a naive parse of them).

fh_raw <- read_excel("data/raw/freedom_house.xlsx", sheet = "Country Ratings, Statuses ", col_names = FALSE)
fh_raw <- as.data.frame(fh_raw)
edition_row <- which(fh_raw[[1]] == "Survey Edition")
year_row <- which(fh_raw[[1]] == "Year(s) Under Review")
pr_row <- year_row + 1
data_start <- pr_row + 1

edition_header <- as.character(fh_raw[edition_row, ])
year_header <- as.character(fh_raw[year_row, ])
pr_cols <- which(as.character(fh_raw[pr_row, ]) == "PR")

parse_fh_year <- function(col) {
  clean_year <- suppressWarnings(as.integer(year_header[col]))
  if (!is.na(clean_year)) return(clean_year)
  parts <- strsplit(edition_header[col], "-")[[1]]
  last <- parts[length(parts)]
  last_num <- suppressWarnings(as.integer(last))
  if (is.na(last_num)) return(NA)
  if (nchar(last) == 2) last_num <- ifelse(last_num > 50, 1900 + last_num, 2000 + last_num)
  last_num - 1
}

fh_long <- do.call(rbind, lapply(pr_cols, function(col) {
  yr <- parse_fh_year(col)
  if (is.na(yr)) return(NULL)
  data.frame(
    country = fh_raw[data_start:nrow(fh_raw), 1],
    year = yr,
    pr = suppressWarnings(as.numeric(fh_raw[data_start:nrow(fh_raw), col])),
    stringsAsFactors = FALSE
  )
}))
fh_long <- fh_long[!is.na(fh_long$country) & fh_long$country != "", ]

# Map country names to ISO3, using the exact strings confirmed present in
# this file (checked directly, not guessed -- several differ from ISO
# naming: "Congo (Brazzaville)", "The Gambia", "Eswatini" with no separate
# "Swaziland" entry, etc.).
name_to_iso3 <- c(
  "Cameroon" = "CMR", "Congo (Brazzaville)" = "COG", "Gabon" = "GAB",
  "Liberia" = "LBR", "Lesotho" = "LSO", "Mali" = "MLI", "Niger" = "NER",
  "Sudan" = "SDN", "Senegal" = "SEN", "Rwanda" = "RWA",
  "Angola" = "AGO", "Benin" = "BEN", "Botswana" = "BWA", "Burkina Faso" = "BFA",
  "Burundi" = "BDI", "Cabo Verde" = "CPV",
  "Central African Republic" = "CAF", "Chad" = "TCD", "Comoros" = "COM",
  "Congo (Kinshasa)" = "COD", "Cote d'Ivoire" = "CIV",
  "Equatorial Guinea" = "GNQ", "Eritrea" = "ERI", "Eswatini" = "SWZ",
  "Ethiopia" = "ETH", "The Gambia" = "GMB", "Ghana" = "GHA", "Guinea" = "GIN",
  "Guinea-Bissau" = "GNB", "Kenya" = "KEN", "Madagascar" = "MDG",
  "Malawi" = "MWI", "Mauritania" = "MRT", "Mauritius" = "MUS",
  "Mozambique" = "MOZ", "Namibia" = "NAM", "Nigeria" = "NGA",
  "Sao Tome and Principe" = "STP", "Seychelles" = "SYC",
  "Sierra Leone" = "SLE", "Somalia" = "SOM", "South Africa" = "ZAF",
  "South Sudan" = "SSD", "Tanzania" = "TZA", "Togo" = "TGO",
  "Uganda" = "UGA", "Zambia" = "ZMB", "Zimbabwe" = "ZWE"
)
fh_long$iso3 <- name_to_iso3[trimws(fh_long$country)]

cat("\n=== Freedom House political rights (PR), 1985-1990 ===\n")
fh_9 <- check_coverage(fh_long, "iso3", "year", "pr", hodler9, pre_window, "Hodler-9")
fh_39 <- check_coverage(fh_long, "iso3", "year", "pr", full_pool, pre_window, "Full-pool")

# ---- 5. UCDP battle deaths, 1991-1993 conflict window ----------------------
# Absence = true zero (no conflict crossed the reporting threshold), not
# missing, for any year from 1989 onward -- confirmed by the sourcing agent.
# Aggregate battle deaths by location country-year (gwno_loc maps to a
# country; using location_inc, the location name field, directly here).

ucdp <- read.csv("data/raw/ucdp_conflict.csv", stringsAsFactors = FALSE)
ucdp_name_to_iso3 <- c(
  "Cameroon" = "CMR", "Congo" = "COG", "Gabon" = "GAB", "Liberia" = "LBR",
  "Lesotho" = "LSO", "Mali" = "MLI", "Niger" = "NER", "Sudan" = "SDN",
  "Senegal" = "SEN", "Rwanda" = "RWA", "DR Congo (Zaire)" = "COD",
  "Burundi" = "BDI", "Uganda" = "UGA", "Tanzania" = "TZA",
  "Somalia" = "SOM", "Ethiopia" = "ETH", "Angola" = "AGO", "Chad" = "TCD",
  "Mozambique" = "MOZ", "Sierra Leone" = "SLE"
)
ucdp$iso3 <- ucdp_name_to_iso3[ucdp$location_inc]
ucdp_agg <- aggregate(bd_best ~ iso3 + year, data = ucdp[!is.na(ucdp$iso3), ], sum)

all_codes <- unique(c(hodler9, full_pool))
ucdp_full <- expand.grid(iso3 = all_codes, year = conflict_window, stringsAsFactors = FALSE)
ucdp_full <- merge(ucdp_full, ucdp_agg, by = c("iso3", "year"), all.x = TRUE)
ucdp_full$bd_best[is.na(ucdp_full$bd_best)] <- 0  # true zero, confirmed

cat("\n=== UCDP battle deaths, 1991-1993 (absence = 0, always complete) ===\n")
cat("Hodler-9 complete for 9 of 9 (by construction, absence = 0)\n")
cat("Full-pool complete for", length(full_pool), "of", length(full_pool), "(by construction, absence = 0)\n")

# ---- 6. Combined verdict: which predictors actually block which donors ----
# All SEVEN predictors now, including hc and the GDP outcome itself
# (rgdpe) -- a country that's predictor-complete but has no GDP data at
# all (Somalia) is not actually usable, so the outcome belongs in this
# check too, not just the six external predictors.

gdp_9 <- check_coverage(pwt80, "countrycode", "year", "rgdpe", hodler9, pre_window, "Hodler-9")
gdp_full <- check_coverage(pwt80, "countrycode", "year", "rgdpe", full_pool, pre_window, "Full-pool")

cat("\n\n=== COMBINED (STRICT: every year 1985-1990 present, all 7 predictors + GDP) ===\n")
combined_9 <- gdp_9 & hc_9 & pwt_ki_9 & pwt_openk_9 & wdi_9 & pol_9 & fh_9
print(combined_9)
cat("All 9 pass:", all(combined_9), "\n")
combined_full <- gdp_full & hc_full & pwt_ki_39 & pwt_openk_39 & wdi_39 & pol_39 & fh_39
cat(sum(combined_full), "of", length(full_pool), "full-pool donors pass all seven predictors + GDP (strict).\n")
cat("Passing:", paste(full_pool[combined_full], collapse = ", "), "\n")
cat("For comparison, Hodler's own manuscript reports a placebo pool of exactly 22 countries\n")
cat("(Figure 1: \"D: 1, N: 22\" -- 23 candidates, 1 dropped by his own exclusion rule).\n")
cat("Strict-completeness count above:", sum(combined_full), "+ Rwanda vs. his 22 + Rwanda.\n")

cat("\n=== COMBINED (LENIENT: na.rm=TRUE mean, >=1 real year in window) ===\n")
hc_9_any <- check_any(pwt80, "countrycode", "year", "hc", hodler9, pre_window, "hc")
wdi_9_any <- check_any(wdi, "countrycode", "year", "inflation_deflator_pct", hodler9, pre_window, "WDI")
pol_9_any <- check_any(polity, "scode", "year", "polity2", hodler9, pre_window, "Polity")
fh_9_any <- check_any(fh_long, "iso3", "year", "pr", hodler9, pre_window, "FH")
combined_9_any <- gdp_9 & hc_9_any & pwt_ki_9 & pwt_openk_9 & wdi_9_any & pol_9_any & fh_9_any
print(combined_9_any)
cat("All 9 pass (lenient):", all(combined_9_any), "\n")

hc_full_any <- check_any(pwt80, "countrycode", "year", "hc", full_pool, pre_window, "hc")
wdi_39_any <- check_any(wdi, "countrycode", "year", "inflation_deflator_pct", full_pool, pre_window, "WDI")
pol_39_any <- check_any(polity, "scode", "year", "polity2", full_pool, pre_window, "Polity")
fh_39_any <- check_any(fh_long, "iso3", "year", "pr", full_pool, pre_window, "FH")
combined_full_any <- gdp_full & hc_full_any & pwt_ki_39 & pwt_openk_39 & wdi_39_any & pol_39_any & fh_39_any
cat(sum(combined_full_any), "of", length(full_pool), "full-pool donors pass all seven predictors + GDP (lenient).\n")
cat("Passing:", paste(full_pool[combined_full_any], collapse = ", "), "\n")
cat("Failing:", paste(full_pool[!combined_full_any], collapse = ", "), "\n")
