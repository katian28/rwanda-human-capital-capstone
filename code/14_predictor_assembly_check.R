#!/usr/bin/env Rscript
# Checks whether Hodler's actual predictor set (PWT 7.1 investment/
# openness, WDI inflation, Polity political regime, Freedom House
# political rights, UCDP conflict) can actually be assembled for the
# donors that matter, before rebuilding code/02 around it. Two donor
# sets checked: Hodler's own 9 non-zero-weight donors (the minimum that
# must work), and the project's 39-country full pool (for the eventual
# full-pool placebo test).

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

cat("=== PWT 7.1 investment share (ki), 1985-1990 ===\n")
pwt_ki_9 <- check_coverage(pwt71, "isocode", "year", "ki", hodler9, pre_window, "Hodler-9")
pwt_ki_39 <- check_coverage(pwt71, "isocode", "year", "ki", full_pool, pre_window, "Full-39")

cat("\n=== PWT 7.1 openness (openk), 1985-1990 ===\n")
pwt_openk_9 <- check_coverage(pwt71, "isocode", "year", "openk", hodler9, pre_window, "Hodler-9")
pwt_openk_39 <- check_coverage(pwt71, "isocode", "year", "openk", full_pool, pre_window, "Full-39")

# ---- 2. WDI inflation -------------------------------------------------------

wdi <- read.csv("data/raw/wdi_inflation.csv", stringsAsFactors = FALSE)

cat("\n=== WDI inflation, 1985-1990 ===\n")
wdi_9 <- check_coverage(wdi, "countrycode", "year", "inflation_cpi_pct", hodler9, pre_window, "Hodler-9")
wdi_39 <- check_coverage(wdi, "countrycode", "year", "inflation_cpi_pct", full_pool, pre_window, "Full-39")

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
pol_39 <- check_coverage(polity, "scode", "year", "polity2", full_pool, pre_window, "Full-39")

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
fh_39 <- check_coverage(fh_long, "iso3", "year", "pr", full_pool, pre_window, "Full-39")

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
cat("Full-39 complete for", length(full_pool), "of", length(full_pool), "(by construction, absence = 0)\n")

# ---- 6. Combined verdict: which predictors actually block which donors ----

cat("\n\n=== COMBINED (STRICT: every year 1985-1990 present) ===\n")
combined_9 <- pwt_ki_9 & pwt_openk_9 & wdi_9 & pol_9 & fh_9
print(combined_9)
cat("All 9 pass:", all(combined_9), "\n")
combined_39 <- pwt_ki_39 & pwt_openk_39 & wdi_39 & pol_39 & fh_39
cat(sum(combined_39), "of", length(full_pool), "full-pool donors pass all five predictors (strict).\n")
cat("Passing:", paste(full_pool[combined_39], collapse = ", "), "\n")

cat("\n=== COMBINED (LENIENT: na.rm=TRUE mean, >=1 real year in window) ===\n")
wdi_9_any <- check_any(wdi, "countrycode", "year", "inflation_cpi_pct", hodler9, pre_window, "WDI")
pol_9_any <- check_any(polity, "scode", "year", "polity2", hodler9, pre_window, "Polity")
fh_9_any <- check_any(fh_long, "iso3", "year", "pr", hodler9, pre_window, "FH")
combined_9_any <- pwt_ki_9 & pwt_openk_9 & wdi_9_any & pol_9_any & fh_9_any
print(combined_9_any)
cat("All 9 pass (lenient):", all(combined_9_any), "\n")

wdi_39_any <- check_any(wdi, "countrycode", "year", "inflation_cpi_pct", full_pool, pre_window, "WDI")
pol_39_any <- check_any(polity, "scode", "year", "polity2", full_pool, pre_window, "Polity")
fh_39_any <- check_any(fh_long, "iso3", "year", "pr", full_pool, pre_window, "FH")
combined_39_any <- pwt_ki_39 & pwt_openk_39 & wdi_39_any & pol_39_any & fh_39_any
cat(sum(combined_39_any), "of", length(full_pool), "full-pool donors pass all five predictors (lenient).\n")
cat("Passing:", paste(full_pool[combined_39_any], collapse = ", "), "\n")
cat("Failing:", paste(full_pool[!combined_39_any], collapse = ", "), "\n")
