#!/usr/bin/env Rscript
# Reconstructs Hodler's OWN placebo procedure as closely as this project
# can manage -- not the full-pool whole-period test in code/04, which was
# never actually a reconstruction of his design (see code/14's header and
# docs/paper-facts-replication.md). Two things this script does that
# code/04 does not:
#
# 1. Uses a STRICT-completeness candidate pool (every year 1985-1990
#    present for all seven predictors and GDP itself, not code/04's
#    na.rm=TRUE lenient standard) -- confirmed in code/14 to produce 24
#    candidates, within 2 of the 23 implied by Hodler's own reported
#    N=22 placebo pool (Figure 1: "D: 1, N: 22" -- 23 candidates, 1
#    dropped by his own exclusion rule). This is this project's best
#    independent reconstruction of his candidate list, not a byte-for-
#    byte match -- no author code or data was ever located (see
#    docs/replication-feasibility.md), so a small residual gap (24 vs.
#    23 candidates) is expected and reported honestly, not hidden.
#
# 2. Computes YEAR-SPECIFIC inference, not a single whole-period RMSPE
#    ratio. Confirmed directly from the manuscript (p.6, p.9): for each
#    post-treatment year t, Hodler computes ratio_t = |gap_t| /
#    pre-treatment RMSPE for every unit (Rwanda and every surviving
#    placebo), then reports p_t = (count of placebos with ratio_t >
#    Rwanda's ratio_t) / N -- a SEPARATE p-value per year, declining as
#    cross-country volatility catches up to Rwanda's own gap over time.
#    This is a materially different inference object than code/04's
#    single whole-period rank, and explains why the two can legitimately
#    disagree -- not an inconsistency to resolve, two different
#    questions ("is this year's gap unusual" vs. "is the whole
#    post-period's trajectory unusual").
#
# Run for BOTH rgdpe and rgdpo, since Hodler's own manuscript names
# rgdpo but only rgdpe reproduces his published benchmark (code/01,
# docs/paper-facts-replication.md Step 1) -- this script checks whether
# that finding holds up under his own inference procedure too, not just
# the published-weight reconstruction.

library(readxl)
library(Synth)
library(rgenoud)
library(quadprog)

set.seed(42)

# fit_synth_robust() -- identical to code/02/03/04/12. See code/02 for
# the full derivation, citations, and empirical tests.
fit_synth_robust <- function(dp) {
  X0 <- dp$X0; X1 <- dp$X1; Z0 <- dp$Z0; Z1 <- dp$Z1
  nvarsV <- nrow(X0)
  n_donors <- ncol(X0)

  big <- cbind(X0, X1)
  divisor <- sqrt(apply(big, 1, var))
  scaled <- t(t(big) %*% (1 / divisor * diag(rep(nrow(big), 1))))
  X0.scaled <- scaled[, 1:n_donors]
  X1.scaled <- scaled[, ncol(scaled)]

  solve_w_quadprog <- function(v, X0.scaled, X1.scaled) {
    Vd <- diag(v, nrow = length(v), ncol = length(v))
    H <- t(X0.scaled) %*% Vd %*% X0.scaled
    Dmat <- H + diag(1e-10, n_donors)
    dvec <- as.numeric(t(X1.scaled) %*% Vd %*% X0.scaled)
    Amat <- cbind(rep(1, n_donors), diag(n_donors))
    bvec <- c(1, rep(0, n_donors))
    w <- tryCatch(
      solve.QP(Dmat, dvec, Amat, bvec, meq = 1)$solution,
      error = function(e) rep(1 / n_donors, n_donors)
    )
    w <- pmax(w, 0); w / sum(w)
  }

  fn_v_quadprog <- function(variables.v, X0.scaled, X1.scaled, Z0, Z1) {
    v <- abs(variables.v) / sum(abs(variables.v))
    w <- solve_w_quadprog(v, X0.scaled, X1.scaled)
    as.numeric(t(Z1 - Z0 %*% w) %*% (Z1 - Z0 %*% w)) / nrow(Z0)
  }

  rgV.genoud <- genoud(fn_v_quadprog, nvarsV, X0.scaled = X0.scaled,
                        X1.scaled = X1.scaled, Z0 = Z0, Z1 = Z1, print.level = 0)
  SV1 <- rgV.genoud$par

  Xall <- cbind(X1.scaled, X0.scaled)
  Xall <- cbind(rep(1, ncol(Xall)), t(Xall))
  Zall <- cbind(Z1, Z0)
  Beta <- tryCatch(solve(t(Xall) %*% Xall) %*% t(Xall) %*% t(Zall), error = function(e) NULL)
  SV2 <- if (!is.null(Beta)) {
    Beta <- Beta[-1, , drop = FALSE]
    v2 <- diag(Beta %*% t(Beta))
    v2 / sum(v2)
  } else {
    rep(1 / nvarsV, nvarsV)
  }

  refine <- function(par0) {
    best <- list(par = par0, value = fn_v_quadprog(par0, X0.scaled, X1.scaled, Z0, Z1))
    for (m in c("Nelder-Mead", "BFGS")) {
      r <- tryCatch(
        optim(par0, fn_v_quadprog, X0.scaled = X0.scaled, X1.scaled = X1.scaled,
              Z0 = Z0, Z1 = Z1, method = m),
        error = function(e) NULL
      )
      if (!is.null(r) && r$value < best$value) best <- list(par = r$par, value = r$value)
    }
    best
  }

  cand1 <- refine(SV1)
  cand2 <- refine(SV2)
  winning <- if (cand1$value <= cand2$value) cand1 else cand2
  winning_v <- abs(winning$par) / sum(abs(winning$par))

  w <- solve_w_quadprog(winning_v, X0.scaled, X1.scaled)
  loss_w <- as.numeric(t(Z1 - Z0 %*% w) %*% (Z1 - Z0 %*% w)) / nrow(Z0)

  fit <- synth(dp, quiet = TRUE)
  fit$solution.w[, 1] <- w
  fit$solution.v[1, ] <- winning_v
  fit$loss.w[1, 1] <- loss_w
  fit$loss.v[1, 1] <- winning$value
  fit
}

treatment_year <- 1994
first_year <- 1970
last_year <- 2011
pre_window <- 1985:1990
conflict_window <- 1991:1993

# Strict-completeness 24-country candidate pool (code/14). A subset of
# code/04's lenient 26-country pool (missing SWZ, NAM, which only pass
# under na.rm averaging, not full-window completeness), so every
# crosswalk entry needed below already exists and is reused verbatim.
donors <- c("BEN", "BWA", "CMR", "CAF", "COG", "CIV", "GAB", "GMB",
            "GHA", "KEN", "LSO", "LBR", "MWI", "MLI", "MRT", "MUS",
            "NER", "SEN", "SLE", "ZAF", "SDN", "TGO", "ZMB", "ZWE")

# ---- 1. Load and merge Hodler's full predictor set (identical sourcing
# to code/04; see there and code/02 for the two data-mapping bugs found
# while verifying these) -- everything except the GDP outcome itself,
# which is loaded separately below so both rgdpe and rgdpo can be tried.

pwt80 <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))

hc <- pwt80[pwt80$countrycode %in% c("RWA", donors) & pwt80$year %in% pre_window,
            c("countrycode", "year", "hc")]

pwt71 <- read.csv("data/raw/pwt71.csv", stringsAsFactors = FALSE)
invest_open <- pwt71[pwt71$isocode %in% c("RWA", donors) & pwt71$year %in% pre_window,
                      c("isocode", "year", "ki", "openk")]
names(invest_open)[1] <- "countrycode"

wdi <- read.csv("data/raw/wdi_inflation_deflator.csv", stringsAsFactors = FALSE)
inflation <- wdi[wdi$countrycode %in% c("RWA", donors) & wdi$year %in% pre_window,
                  c("countrycode", "year", "inflation_deflator_pct")]

polity_raw <- as.data.frame(read_excel("data/raw/polity.xls"))
scode_to_iso3 <- c(
  RWA = "RWA", ANG = "AGO", BEN = "BEN", BOT = "BWA", BFO = "BFA",
  CAP = "CPV", CAO = "CMR", CEN = "CAF", CHA = "TCD", COM = "COM",
  CON = "COG", IVO = "CIV", EQG = "GNQ", SWA = "SWZ", ETH = "ETH",
  GAB = "GAB", GAM = "GMB", GHA = "GHA", GUI = "GIN", GNB = "GNB",
  KEN = "KEN", LES = "LSO", LBR = "LBR", MAG = "MDG", MAW = "MWI",
  MLI = "MLI", MAA = "MRT", MAS = "MUS", NAM = "NAM", NIR = "NER",
  NIG = "NGA", SEN = "SEN", SIE = "SLE", SOM = "SOM", SAF = "ZAF",
  SUD = "SDN", TOG = "TGO", ZAM = "ZMB", ZIM = "ZWE"
)
polity_raw$iso3 <- scode_to_iso3[polity_raw$scode]
polity <- polity_raw[!is.na(polity_raw$iso3) & polity_raw$year %in% pre_window,
                      c("iso3", "year", "polity2")]
names(polity)[1] <- "countrycode"

fh_raw <- as.data.frame(read_excel("data/raw/freedom_house.xlsx",
                                    sheet = "Country Ratings, Statuses ", col_names = FALSE))
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
  if (is.na(yr) || !(yr %in% pre_window)) return(NULL)
  data.frame(country = fh_raw[data_start:nrow(fh_raw), 1], year = yr,
             pr = suppressWarnings(as.numeric(fh_raw[data_start:nrow(fh_raw), col])),
             stringsAsFactors = FALSE)
}))
name_to_iso3 <- c(
  Rwanda = "RWA", Benin = "BEN", Botswana = "BWA", Cameroon = "CMR",
  "Central African Republic" = "CAF", "Congo (Brazzaville)" = "COG",
  "Cote d'Ivoire" = "CIV", Gabon = "GAB", "The Gambia" = "GMB",
  Ghana = "GHA", Kenya = "KEN", Lesotho = "LSO", Liberia = "LBR",
  Malawi = "MWI", Mali = "MLI", Mauritania = "MRT", Mauritius = "MUS",
  Niger = "NER", Senegal = "SEN", "Sierra Leone" = "SLE",
  "South Africa" = "ZAF", Sudan = "SDN", Togo = "TGO", Zambia = "ZMB",
  Zimbabwe = "ZWE"
)
fh_long$countrycode <- name_to_iso3[fh_long$country]
political_rights <- fh_long[!is.na(fh_long$countrycode), c("countrycode", "year", "pr")]

ucdp <- read.csv("data/raw/ucdp_conflict.csv", stringsAsFactors = FALSE)
ucdp_name_to_iso3 <- c(
  Rwanda = "RWA", Benin = "BEN", Botswana = "BWA", Cameroon = "CMR",
  "Central African Republic" = "CAF", Congo = "COG", "Ivory Coast" = "CIV",
  Gabon = "GAB", Gambia = "GMB", Ghana = "GHA", Kenya = "KEN",
  Lesotho = "LSO", Liberia = "LBR", Malawi = "MWI", Mali = "MLI",
  Mauritania = "MRT", Mauritius = "MUS", Niger = "NER", Senegal = "SEN",
  "Sierra Leone" = "SLE", "South Africa" = "ZAF", Sudan = "SDN",
  Togo = "TGO", Zambia = "ZMB", Zimbabwe = "ZWE"
)
ucdp$countrycode <- ucdp_name_to_iso3[ucdp$location_inc]
conflict_avg <- aggregate(bd_best ~ countrycode, data = ucdp[!is.na(ucdp$countrycode) & ucdp$year %in% conflict_window, ],
                           FUN = function(x) sum(x) / length(conflict_window))
conflict <- merge(data.frame(countrycode = c("RWA", donors)), conflict_avg, all.x = TRUE)
conflict$bd_best[is.na(conflict$bd_best)] <- 0
conflict_grid <- expand.grid(countrycode = c("RWA", donors), year = conflict_window, stringsAsFactors = FALSE)
conflict <- merge(conflict_grid, conflict, by = "countrycode")

non_gdp_panel <- invest_open
non_gdp_panel <- merge(non_gdp_panel, hc, by = c("countrycode", "year"), all = TRUE)
non_gdp_panel <- merge(non_gdp_panel, inflation, by = c("countrycode", "year"), all = TRUE)
non_gdp_panel <- merge(non_gdp_panel, polity, by = c("countrycode", "year"), all = TRUE)
non_gdp_panel <- merge(non_gdp_panel, political_rights, by = c("countrycode", "year"), all = TRUE)
non_gdp_panel <- merge(non_gdp_panel, conflict[, c("countrycode", "year", "bd_best")], by = c("countrycode", "year"), all = TRUE)

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

odd_years <- seq(1971, 1993, by = 2)
all_units <- c("RWA", donors)
years <- first_year:last_year

# ---- 2. One function that fits a synthetic control for ANY treated unit,
# for a given GDP variable, returning the FULL year-by-year path (not
# just pre/post RMSPE) -- year-specific inference needs every year's gap.

fit_one_unit <- function(treated_code, control_codes, panel, id_lookup, special_predictors) {
  treated_id <- id_lookup$unit_id[id_lookup$countrycode == treated_code]
  control_ids <- id_lookup$unit_id[id_lookup$countrycode %in% control_codes]

  dp <- dataprep(
    foo = panel,
    dependent = "gdp",
    unit.variable = "unit_id",
    unit.names.variable = "countrycode",
    time.variable = "year",
    treatment.identifier = treated_id,
    controls.identifier = control_ids,
    time.predictors.prior = first_year:(treatment_year - 1),
    time.optimize.ssr = first_year:(treatment_year - 1),
    time.plot = years,
    special.predictors = special_predictors
  )

  fit <- fit_synth_robust(dp)
  actual <- dp$Y1plot[, 1]
  synthetic <- as.numeric(dp$Y0plot %*% fit$solution.w)
  gap <- actual - synthetic
  pre_rmspe <- sqrt(mean(gap[years < treatment_year]^2))

  data.frame(unit = treated_code, year = years, actual = actual, synthetic = synthetic,
             gap = gap, pre_rmspe = pre_rmspe)
}

# ---- 3. Run the whole reconstruction for one GDP variable ------------------

run_reconstruction <- function(gdp_var) {
  cat("\n\n########## GDP variable:", gdp_var, "##########\n")

  gdp <- pwt80[pwt80$countrycode %in% c("RWA", donors) & pwt80$year %in% years, c("countrycode", "year", gdp_var)]
  names(gdp)[3] <- "gdp"
  for (c_ in unique(gdp$countrycode)) {
    m <- gdp$countrycode == c_
    baseline <- mean(gdp$gdp[m & gdp$year %in% 1991:1993])
    gdp$gdp[m] <- gdp$gdp[m] / baseline
  }

  panel <- merge(gdp, non_gdp_panel, by = c("countrycode", "year"), all.x = TRUE)
  panel$unit_id <- as.numeric(factor(panel$countrycode))
  id_lookup <- unique(panel[, c("countrycode", "unit_id")])

  special_predictors <- c(
    lapply(odd_years, function(yr) list("gdp", yr, "mean")),
    list(
      list("gdp", pre_window, "mean"),
      list("hc", pre_window, "mean"),
      list("ki", pre_window, "mean"),
      list("openk", pre_window, "mean"),
      list("inflation_deflator_pct", pre_window, "mean"),
      list("polity2", pre_window, "mean"),
      list("pr", pre_window, "mean"),
      list("bd_best", conflict_window, "mean")
    )
  )

  cat("Fitting", length(all_units), "synthetic controls (Rwanda + every candidate as a placebo)...\n")
  paths <- data.frame()
  for (treated in all_units) {
    others <- setdiff(donors, treated)
    one_result <- fit_one_unit(treated, others, panel, id_lookup, special_predictors)
    paths <- rbind(paths, one_result)
    cat(".")
  }
  cat("\n")

  # ---- Hodler's own exclusion rule: drop PLACEBO units (never Rwanda)
  # with pre-treatment RMSPE above the placebo group's median + 1 SD,
  # computed from the placebo group only -- same rule, same order of
  # operations as code/05.
  pre_rmspe_by_unit <- unique(paths[, c("unit", "pre_rmspe")])
  placebo_rmspe <- pre_rmspe_by_unit$pre_rmspe[pre_rmspe_by_unit$unit != "RWA"]
  threshold <- median(placebo_rmspe) + sd(placebo_rmspe)
  dropped <- pre_rmspe_by_unit$unit[pre_rmspe_by_unit$unit != "RWA" & pre_rmspe_by_unit$pre_rmspe > threshold]
  surviving_placebos <- setdiff(donors, dropped)

  cat("Exclusion-rule threshold:", round(threshold, 4), "\n")
  cat("Dropped", length(dropped), "placebo(s):", paste(dropped, collapse = ", "), "\n")
  cat("Surviving placebo pool: N =", length(surviving_placebos), "(Hodler reports N = 22)\n")

  # ---- Year-specific inference, Hodler's own convention: ratio_t(unit) =
  # |gap_t| / pre-treatment RMSPE(unit); p_t = (# surviving placebos with
  # ratio_t > Rwanda's ratio_t) / N -- Rwanda excluded from the
  # denominator and from the comparison set, matching his own reported
  # arithmetic exactly ("2/22=0.09").
  paths$ratio <- abs(paths$gap) / paths$pre_rmspe
  post_years <- years[years >= treatment_year]

  rwanda_ratios <- paths$ratio[paths$unit == "RWA" & paths$year %in% post_years]
  names(rwanda_ratios) <- post_years

  placebo_paths <- paths[paths$unit %in% surviving_placebos & paths$year %in% post_years, ]
  year_specific <- data.frame(
    year = post_years,
    rwanda_gap = paths$gap[paths$unit == "RWA" & paths$year %in% post_years],
    rwanda_ratio = as.numeric(rwanda_ratios),
    n_exceeding = sapply(post_years, function(yr) {
      sum(placebo_paths$ratio[placebo_paths$year == yr] > rwanda_ratios[as.character(yr)])
    }),
    n_placebos = length(surviving_placebos)
  )
  year_specific$p_value <- year_specific$n_exceeding / year_specific$n_placebos

  write.csv(paths, sprintf("results/hodler-reconstruction-%s-paths.csv", gdp_var), row.names = FALSE)
  write.csv(year_specific, sprintf("results/hodler-reconstruction-%s-year-specific.csv", gdp_var), row.names = FALSE)

  cat("\nYear-specific inference (", gdp_var, "):\n", sep = "")
  print(year_specific[, c("year", "rwanda_gap", "p_value")], row.names = FALSE)

  # ---- Whole-period rank, for direct comparison with code/04's approach
  # on this SAME 24-candidate strict pool (so the only thing that changes
  # relative to code/04 is the pool, isolating that effect from the
  # year-specific-vs-whole-period effect).
  whole_period <- aggregate(gap ~ unit, data = paths[paths$year %in% post_years, ],
                             FUN = function(g) sqrt(mean(g^2)))
  names(whole_period)[2] <- "post_rmspe"
  whole_period <- merge(whole_period, pre_rmspe_by_unit, by = "unit")
  whole_period$whole_ratio <- whole_period$post_rmspe / whole_period$pre_rmspe
  whole_period_surviving <- whole_period[whole_period$unit %in% c("RWA", surviving_placebos), ]
  whole_period_surviving <- whole_period_surviving[order(-whole_period_surviving$whole_ratio), ]
  whole_period_surviving$rank <- seq_len(nrow(whole_period_surviving))
  rwanda_whole_rank <- whole_period_surviving$rank[whole_period_surviving$unit == "RWA"]
  rwanda_whole_p <- rwanda_whole_rank / nrow(whole_period_surviving)

  cat("\nWhole-period rank on this same strict pool (for comparison with code/04):\n")
  cat("Rwanda's rank:", rwanda_whole_rank, "of", nrow(whole_period_surviving),
      sprintf("(p = %.3f)\n", rwanda_whole_p))

  list(year_specific = year_specific, dropped = dropped, n_surviving = length(surviving_placebos),
       whole_rank = rwanda_whole_rank, whole_n = nrow(whole_period_surviving), whole_p = rwanda_whole_p)
}

result_rgdpe <- run_reconstruction("rgdpe")
result_rgdpo <- run_reconstruction("rgdpo")

cat("\n\n========== SUMMARY ==========\n")
cat("rgdpe: dropped", paste(result_rgdpe$dropped, collapse = ", "), "-> N =", result_rgdpe$n_surviving,
    "| whole-period rank", result_rgdpe$whole_rank, "of", result_rgdpe$whole_n,
    sprintf("(p = %.3f)\n", result_rgdpe$whole_p))
cat("rgdpo: dropped", paste(result_rgdpo$dropped, collapse = ", "), "-> N =", result_rgdpo$n_surviving,
    "| whole-period rank", result_rgdpo$whole_rank, "of", result_rgdpo$whole_n,
    sprintf("(p = %.3f)\n", result_rgdpo$whole_p))
