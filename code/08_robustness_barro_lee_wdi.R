#!/usr/bin/env Rscript

# Section 5 robustness: Barro-Lee attainment and WDI/UIS secondary enrollment.
# Both are descriptive corroboration only, per docs/data-availability.md:
# Barro-Lee is five-year-interval and cannot resolve annual timing; WDI
# enrollment is missing Rwanda 1994-1998 and cannot support a synthetic
# control. Neither is a substitute for the PWT GDP/hc synthetic controls
# (code/01-07) -- they are sanity checks on the same qualitative story.
#
# Comparison countries are the donors that already carried the most weight
# in this project's own synthetic controls (GDP re-estimation, code/02;
# human-capital extension, code/07), for continuity rather than picking a
# new comparison set ad hoc.

suppressPackageStartupMessages(library(jsonlite))

dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

comparators <- c(CMR = "Cameroon", SEN = "Senegal", ZMB = "Zambia", MLI = "Mali",
                  CIV = "Cote d'Ivoire", NER = "Niger", MOZ = "Mozambique", ZAF = "South Africa")
treatment_year <- 1994

# ---- Barro-Lee educational attainment (five-year intervals) --------------

bl_file <- "data/raw/BL_v3_MF1564.csv"
bl_url <- "https://raw.githubusercontent.com/barrolee/BarroLeeDataSet/master/BLData/BL_v3_MF1564.csv"
if (!file.exists(bl_file)) download.file(bl_url, bl_file, quiet = TRUE)

bl <- read.csv(bl_file, stringsAsFactors = FALSE)
bl_units <- c("RWA", names(comparators))
bl_sub <- bl[bl$WBcode %in% bl_units & bl$year %in% seq(1950, 2015, 5), c("WBcode", "year", "yr_sch")]
bl_wide <- reshape(bl_sub, idvar = "year", timevar = "WBcode", direction = "wide")
names(bl_wide) <- sub("^yr_sch\\.", "", names(bl_wide))
bl_wide <- bl_wide[order(bl_wide$year), ]
write.csv(bl_wide, "results/robustness-barro-lee.csv", row.names = FALSE)

rwa_1990 <- bl_wide$RWA[bl_wide$year == 1990]
rwa_1995 <- bl_wide$RWA[bl_wide$year == 1995]
rwa_change <- rwa_1995 - rwa_1990
comparator_changes <- sapply(names(comparators), function(code) {
  v90 <- bl_wide[[code]][bl_wide$year == 1990]
  v95 <- bl_wide[[code]][bl_wide$year == 1995]
  v95 - v90
})

# ---- WDI secondary enrollment (descriptive, 1999 onward) ------------------

fetch_wdi <- function(iso3) {
  url <- sprintf("https://api.worldbank.org/v2/country/%s/indicator/SE.SEC.ENRR?format=json&per_page=200", iso3)
  raw <- tryCatch(fromJSON(url, flatten = TRUE), error = function(e) NULL)
  if (is.null(raw) || length(raw) < 2 || is.null(raw[[2]])) return(NULL)
  df <- raw[[2]][, c("date", "value")]
  df$year <- as.integer(df$date)
  df$countrycode <- iso3
  df[, c("countrycode", "year", "value")]
}

wdi_units <- c("RWA", names(comparators))
wdi_list <- lapply(wdi_units, fetch_wdi)
wdi <- do.call(rbind, wdi_list[!sapply(wdi_list, is.null)])
wdi <- wdi[wdi$year >= 1990 & wdi$year <= 2011, ]
write.csv(wdi, "results/robustness-wdi-enrollment.csv", row.names = FALSE)

rwanda_missing <- setdiff(1994:1998, wdi$year[wdi$countrycode == "RWA" & !is.na(wdi$value)])

# ---- Report ----------------------------------------------------------------

lines <- c(
  "# Robustness: Barro-Lee attainment and WDI secondary enrollment",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "Both checks are descriptive corroboration, not synthetic-control estimates -- per `docs/data-availability.md`, Barro-Lee's five-year frequency cannot resolve annual recovery timing, and WDI enrollment is missing Rwanda 1994-1998 so cannot support a balanced-panel design. Comparison countries are the donors that already carried the most weight in this project's GDP re-estimation (code/02) and human-capital extension (code/07): Cameroon, Senegal, Zambia, Mali, Cote d'Ivoire, Niger, Mozambique, South Africa.",
  "",
  "## Barro-Lee mean years of schooling (ages 15-64), five-year intervals",
  "",
  sprintf("Rwanda's average years of schooling: %.2f in 1990, %.2f in 1995 (change: %+.2f). The 1995 observation is the first data point after the genocide at this frequency; the true 1994 low point cannot be resolved.", rwa_1990, rwa_1995, rwa_change),
  "",
  "**1990-to-1995 change, Rwanda vs. comparators:**",
  "",
  "| Country | 1990 | 1995 | Change |",
  "| --- | --- | --- | --- |",
  paste0("| Rwanda | ", sprintf("%.2f", rwa_1990), " | ", sprintf("%.2f", rwa_1995), " | ", sprintf("%+.2f", rwa_change), " |"),
  paste0("| ", comparators, " | ",
    sprintf("%.2f", sapply(names(comparators), function(c) bl_wide[[c]][bl_wide$year == 1990])), " | ",
    sprintf("%.2f", sapply(names(comparators), function(c) bl_wide[[c]][bl_wide$year == 1995])), " | ",
    sprintf("%+.2f", comparator_changes), " |", collapse = "\n"),
  "",
  sprintf("Rwanda's 1990-1995 change (%+.2f) is %s the comparator range (%+.2f to %+.2f). Since Barro-Lee attainment is built from census/survey data with substantial interpolation between rounds, a five-year change of this size is not strong evidence either way -- it is consistent with, but does not confirm, the flat/positive PWT `hc` result in Section 4.", rwa_change, if (rwa_change < min(comparator_changes)) "below" else if (rwa_change > max(comparator_changes)) "above" else "within", min(comparator_changes), max(comparator_changes)),
  "",
  "## WDI secondary enrollment (descriptive, 1990-2011)",
  "",
  sprintf("Rwanda is missing %s (confirming the balanced-panel audit in `docs/data-availability.md`). From 1999 onward, Rwanda's gross secondary enrollment rises from single digits to the mid-30s by 2011 (see `results/robustness-wdi-enrollment.csv` and the figure) -- a visible recovery trajectory, but the series cannot speak to the 1994-1998 period at all, so it cannot corroborate or contradict a 1994 shock directly.", paste(rwanda_missing, collapse = ", ")),
  "",
  "## Interpretation",
  "",
  "Neither check moves the paper's conclusions on its own. Barro-Lee is too coarse and too smoothed by interpolation to add power beyond the PWT `hc` result; WDI enrollment simply cannot see the years that matter. Both are included because the paper's own design documents (`docs/data-availability.md`) committed to reporting them, not because either is informative on its own -- this should be stated plainly in the paper rather than presented as if it strengthens the case."
)
writeLines(lines, "results/robustness-checks.md")

png("figures/robustness-barro-lee.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  bl_wide$year, bl_wide$RWA, type = "o", lwd = 3, col = "#111827", pch = 16,
  xlab = "Year", ylab = "Mean years of schooling, ages 15-64",
  main = "Barro-Lee attainment: Rwanda vs. comparators",
  ylim = range(bl_wide[, c("RWA", names(comparators))], na.rm = TRUE),
  xlim = c(1970, 2015)
)
palette_cols <- c("#2563EB", "#059669", "#D97706", "#DC2626", "#7C3AED", "#0891B2", "#DB2777")
for (i in seq_along(comparators)) {
  code <- names(comparators)[i]
  lines(bl_wide$year, bl_wide[[code]], col = palette_cols[i], lwd = 1.5, lty = 2)
}
abline(v = treatment_year, lty = 3, lwd = 2, col = "#00000088")
legend("topleft", legend = c("Rwanda", comparators), col = c("#111827", palette_cols), lty = c(1, rep(2, length(comparators))), lwd = c(3, rep(1.5, length(comparators))), bty = "n", cex = 0.7)
mtext("Five-year intervals; 1994 genocide marked. Descriptive only, not a synthetic control.", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

png("figures/robustness-wdi-enrollment.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
rwa_wdi <- wdi[wdi$countrycode == "RWA", ]
plot(
  rwa_wdi$year, rwa_wdi$value, type = "o", lwd = 3, col = "#111827", pch = 16,
  xlab = "Year", ylab = "Gross secondary enrollment (%)",
  main = "WDI secondary enrollment: Rwanda, descriptive",
  xlim = c(1990, 2011)
)
rect(1994, par("usr")[3], 1998, par("usr")[4], col = "#DC262622", border = NA)
abline(v = treatment_year, lty = 3, lwd = 2, col = "#DC2626")
legend("topleft", legend = c("Rwanda", "1994 genocide", "1994-1998 (no data)"), col = c("#111827", "#DC2626", "#DC262688"), lty = c(1, 3, NA), lwd = c(3, 2, NA), pch = c(16, NA, 15), bty = "n")
mtext("Rwanda has no observations 1994-1998; series cannot speak to that period.", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(lines, collapse = "\n"), "\n")
