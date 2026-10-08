#!/usr/bin/env Rscript
# Public-health service-delivery recovery extension. Same two steps as the
# GDP version (code/02 and code/04): first fit Rwanda's synthetic control
# and look at the gap, then run the same fit for every donor country as a
# placebo to see how unusual Rwanda's gap really is.
#
# Outcome variable: DTP3 immunization coverage (WHO/UNICEF WUENIC), not
# PWT's hc. hc, fertility rate, infant mortality rate, and government
# education/health expenditure were all tried and rejected -- see
# docs/data-availability.md for the full history. Immunization coverage
# passed the balanced-panel feasibility screen in code/11 and is
# genuinely administrative-report data, not a demographic model smoothed
# between infrequent surveys.
#
# This measures something different from what hc was meant to measure:
# whether the health system was functioning well enough in a given year
# to actually vaccinate infants -- public-health service-delivery /
# state-capacity recovery, not a stock of human capital. Treat this as a
# deliberate reframing of the extension's research question, not a
# like-for-like swap of the outcome variable. See
# docs/data-availability.md's "immunization coverage" entry.
#
# Three special predictors beyond the lagged outcome itself, each
# averaged over 1989-1993 (the most recent pre-treatment years, chosen
# because UCDP conflict data doesn't exist before 1989 -- same logic as
# Hodler's own recent-years average window in the GDP replication):
#   - MCV1 (measles) coverage: same WHO/UNICEF WUENIC source as DTP3,
#     measures the same underlying thing (routine immunization system
#     functioning) without being the outcome itself.
#   - UCDP conflict (battle deaths): conflict disrupts the cold chain,
#     clinic access, and health-worker safety directly -- not just a
#     generic governance proxy, a specific mechanism for vaccination.
#   - GDP per capita (PWT rgdpe/pop): wealth proxies general health-
#     system capacity and financing.
# All three are already-sourced, genuinely annual data (no interpolated
# series), consistent with why DTP3 itself was chosen over hc. GDP per
# capita has zero PWT coverage for Somalia and Seychelles (checked
# directly, not assumed -- PWT has no rows for either), so both are
# dropped from the donor pool below; Somalia's exclusion is also a
# known fix for the baseline-dominance problem flagged in code/13.

library(Synth)
library(rgenoud)
library(quadprog)
library(readxl)

set.seed(42)

# fit_synth_robust() reimplements synth()'s own documented algorithm
# (Abadie, Diamond & Hainmueller 2011, JSS 42(13), section 3.2, matching
# ?synth and Synth's source exactly): try TWO starting points for V (equal
# weights, and a regression-based guess), each refined via Nelder-Mead and
# BFGS, keep whichever wins; with genoud, add a third candidate (genoud's
# global search), likewise only a starting point, always locally refined
# afterward, never used raw. The one deviation: the quadratic program for
# W (given a V) is solved with quadprog instead of kernlab's ipop, which
# synth() uses internally -- ipop turned out to be numerically fragile on
# this project's data near sparse W solutions, and not just by erroring:
# it can silently return a markedly worse W for the same V with no error
# at all. quadprog solves the identical equation; it's a solver swap, not
# a change to the method. See code/02 for the full derivation, citations,
# and empirical tests.
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

  fit <- synth(dp, quiet = TRUE)  # only used as a template for solution.w/v's dimnames etc.
  fit$solution.w[, 1] <- w
  fit$solution.v[1, ] <- winning_v
  fit$loss.w[1, 1] <- loss_w
  fit$loss.v[1, 1] <- winning$value
  fit
}

# ---- 1. Load the raw data -------------------------------------------------
# Same WHO/UNICEF WUENIC DTP3 panel downloaded and checked in code/11.

dtp3 <- read.csv("data/raw/who_dtp3_coverage.csv", stringsAsFactors = FALSE)
names(dtp3) <- c("country_name", "countrycode", "year", "dtp3")

# ---- 2. Build the donor pool -----------------------------------------------
# Same Sub-Saharan Africa candidate list as the GDP and hc versions, kept
# only if the country has complete DTP3 coverage over the full window.

ssa_all <- c(
  "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD", "COM",
  "COD", "COG", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA",
  "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
  "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM",
  "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE"
)
excluded <- c("BDI", "COD", "TZA", "UGA")
candidates <- setdiff(ssa_all, c("RWA", excluded))

treatment_year <- 1994
first_year <- 1981  # Rwanda's WUENIC DTP3 series starts here (code/11)
last_year <- 2011
outcome_var <- "dtp3"

coverage <- dtp3[dtp3$countrycode %in% candidates & dtp3$year %in% first_year:last_year, ]
complete_years <- tapply(!is.na(coverage[[outcome_var]]), coverage$countrycode, sum)
donors <- names(complete_years)[complete_years == length(first_year:last_year)]
cat(length(donors), "donors have complete DTP3 coverage,", first_year, "-", last_year, "\n")

# GDP per capita (PWT rgdpe/pop) has zero coverage at all for Somalia and
# Seychelles -- confirmed directly against the downloaded file, not
# assumed. Drop them here so every remaining donor has real data for
# every special predictor used below.
pwt80 <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))
gdp_pc_window <- 1989:1993
gdp_pc_check <- pwt80[pwt80$countrycode %in% donors & pwt80$year %in% gdp_pc_window, ]
gdp_pc_ok <- tapply(!is.na(gdp_pc_check$rgdpe) & !is.na(gdp_pc_check$pop), gdp_pc_check$countrycode, sum)
no_gdp_pc <- setdiff(donors, names(gdp_pc_ok)[gdp_pc_ok > 0])
donors <- setdiff(donors, no_gdp_pc)
cat("Dropped for missing GDP-per-capita data:", paste(no_gdp_pc, collapse = ", "), "\n")
cat(length(donors), "donors remain after the GDP-per-capita completeness check\n")

# ---- 3. Build the panel (Rwanda + all donors) ------------------------------
# NOT normalized to a baseline, unlike code/02 (GDP) and code/07 (hc). DTP3
# is already a percentage on a common 0-100 scale across every country, so
# it doesn't need normalizing to be comparable the way GDP levels do.
# Dividing a BOUNDED percentage by its own baseline is actively distorting:
# a country starting near 90% coverage has almost no room to rise above 1.0
# (ceiling effect), while a low-baseline country has enormous room to swing
# far above 1.0 from a modest percentage-point gain -- plausibly part of why
# Somalia (baseline ~21%) dominated the synthetic control's weights in the
# normalized version. Raw percentage-point levels avoid this asymmetry.

panel <- dtp3[dtp3$countrycode %in% c("RWA", donors) & dtp3$year %in% first_year:last_year,
              c("countrycode", "year", outcome_var)]
names(panel)[3] <- "coverage"

# ---- 3b. Load and merge the three external predictors ---------------------
# All averaged over 1989-1993 (see header comment for why that window and
# why these three). MCV1 uses the same WUENIC source/structure as DTP3.

mcv1_raw <- read.csv("data/raw/who_mcv1_coverage.csv", stringsAsFactors = FALSE)
names(mcv1_raw) <- c("country_name", "countrycode", "year", "mcv1")
mcv1 <- mcv1_raw[mcv1_raw$countrycode %in% c("RWA", donors) & mcv1_raw$year %in% first_year:last_year,
                  c("countrycode", "year", "mcv1")]

gdp_pc <- pwt80[pwt80$countrycode %in% c("RWA", donors) & pwt80$year %in% first_year:last_year,
                c("countrycode", "year", "rgdpe", "pop")]
gdp_pc$gdp_pc <- gdp_pc$rgdpe / gdp_pc$pop

ucdp <- read.csv("data/raw/ucdp_conflict.csv", stringsAsFactors = FALSE)
ucdp_name_to_iso3 <- c(
  Rwanda = "RWA", Botswana = "BWA", "Central African Republic" = "CAF",
  Cameroon = "CMR", Congo = "COG", Ethiopia = "ETH", Ghana = "GHA",
  Gambia = "GMB", Lesotho = "LSO", Mozambique = "MOZ", Mauritania = "MRT",
  Mauritius = "MUS", Malawi = "MWI", Niger = "NER", Sudan = "SDN",
  "Sao Tome and Principe" = "STP", Swaziland = "SWZ", Togo = "TGO",
  Zimbabwe = "ZWE"
)
conflict_window <- 1989:1993
ucdp$countrycode <- ucdp_name_to_iso3[ucdp$location_inc]
conflict_avg <- aggregate(bd_best ~ countrycode, data = ucdp[!is.na(ucdp$countrycode) & ucdp$year %in% conflict_window, ],
                           FUN = function(x) sum(x) / length(conflict_window))
conflict <- merge(data.frame(countrycode = c("RWA", donors)), conflict_avg, all.x = TRUE)
conflict$bd_best[is.na(conflict$bd_best)] <- 0
conflict_grid <- expand.grid(countrycode = c("RWA", donors), year = conflict_window, stringsAsFactors = FALSE)
conflict <- merge(conflict_grid, conflict, by = "countrycode")

panel <- merge(panel, mcv1, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, gdp_pc[, c("countrycode", "year", "gdp_pc")], by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, conflict[, c("countrycode", "year", "bd_best")], by = c("countrycode", "year"), all.x = TRUE)

panel$unit_id <- as.numeric(factor(panel$countrycode))
id_lookup <- unique(panel[, c("countrycode", "unit_id")])

ext_predictors <- list(
  list("mcv1", conflict_window, "mean"),
  list("gdp_pc", conflict_window, "mean"),
  list("bd_best", conflict_window, "mean")
)

# ---- 4. Fit Rwanda's synthetic control (the main result) ------------------
# Three special predictors spanning the shorter 1981-1993 pre-treatment
# window (13 years, vs. 24 for GDP/hc), split the same way: early, middle,
# immediately pre-treatment, plus the three external predictors above.

rwanda_id <- id_lookup$unit_id[id_lookup$countrycode == "RWA"]
donor_ids <- id_lookup$unit_id[id_lookup$countrycode %in% donors]

dp_main <- dataprep(
  foo = panel,
  dependent = "coverage",
  unit.variable = "unit_id",
  unit.names.variable = "countrycode",
  time.variable = "year",
  treatment.identifier = rwanda_id,
  controls.identifier = donor_ids,
  time.predictors.prior = first_year:(treatment_year - 1),
  time.optimize.ssr = first_year:(treatment_year - 1),
  time.plot = first_year:last_year,
  special.predictors = c(
    list(
      list("coverage", 1981:1985, "mean"),
      list("coverage", 1986:1989, "mean"),
      list("coverage", 1990:1993, "mean")
    ),
    ext_predictors
  )
)

synth_main <- fit_synth_robust(dp_main)

print(synth.tab(synth.res = synth_main, dataprep.res = dp_main))

dir.create("figures", showWarnings = FALSE)
png("figures/immunization-extension-path.png", width = 1400, height = 900, res = 150)
path.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "DTP3 immunization coverage (%)",
  Xlab = "Year",
  Main = "Rwanda immunization coverage: actual vs. synthetic",
  Legend = c("Rwanda", "Synthetic Rwanda")
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

png("figures/immunization-extension-gaps.png", width = 1400, height = 900, res = 150)
gaps.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "Gap (actual - synthetic, percentage points)",
  Xlab = "Year",
  Main = "Rwanda immunization coverage gap"
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

dir.create("results", showWarnings = FALSE)
actual_main <- dp_main$Y1plot[, 1]
synthetic_main <- as.numeric(dp_main$Y0plot %*% synth_main$solution.w)
path_table <- data.frame(year = first_year:last_year, actual = actual_main, synthetic = synthetic_main)
path_table$gap <- path_table$actual - path_table$synthetic
write.csv(path_table, "results/immunization-extension-path.csv", row.names = FALSE)

weights_table <- data.frame(donor = donors, weight = round(as.numeric(synth_main$solution.w), 4))
write.csv(weights_table, "results/immunization-extension-weights.csv", row.names = FALSE)

pre_rmspe_main <- sqrt(mean(path_table$gap[path_table$year < treatment_year]^2))
post_gap_main <- path_table$gap[path_table$year >= treatment_year]
cat("\nMain result -- pre-treatment RMSPE:", round(pre_rmspe_main, 5), "\n")
cat("1994 gap:", round(path_table$gap[path_table$year == 1994], 3), "\n")
cat("Average post-treatment gap:", round(mean(post_gap_main), 3), "\n")

# ---- 5. Placebo test: run the same fit for every donor as if IT were treated

fit_one_unit <- function(treated_code, control_codes) {
  treated_id <- id_lookup$unit_id[id_lookup$countrycode == treated_code]
  control_ids <- id_lookup$unit_id[id_lookup$countrycode %in% control_codes]

  dp <- dataprep(
    foo = panel,
    dependent = "coverage",
    unit.variable = "unit_id",
    unit.names.variable = "countrycode",
    time.variable = "year",
    treatment.identifier = treated_id,
    controls.identifier = control_ids,
    time.predictors.prior = first_year:(treatment_year - 1),
    time.optimize.ssr = first_year:(treatment_year - 1),
    time.plot = first_year:last_year,
    special.predictors = c(
      list(
        list("coverage", 1981:1985, "mean"),
        list("coverage", 1986:1989, "mean"),
        list("coverage", 1990:1993, "mean")
      ),
      ext_predictors
    )
  )

  fit <- fit_synth_robust(dp)

  actual <- dp$Y1plot[, 1]
  synthetic <- as.numeric(dp$Y0plot %*% fit$solution.w)
  gap <- actual - synthetic

  years <- first_year:last_year
  pre_rmspe <- sqrt(mean(gap[years < treatment_year]^2))
  post_rmspe <- sqrt(mean(gap[years >= treatment_year]^2))

  data.frame(unit = treated_code, pre_rmspe = pre_rmspe, post_rmspe = post_rmspe,
             ratio = post_rmspe / pre_rmspe)
}

all_units <- c("RWA", donors)
cat("\nFitting", length(all_units), "synthetic controls for the placebo test...\n")

placebo_results <- data.frame()
for (treated in all_units) {
  others <- setdiff(donors, treated)
  one_result <- fit_one_unit(treated, others)
  placebo_results <- rbind(placebo_results, one_result)
  cat(".")
}
cat("\n")

placebo_results <- placebo_results[order(-placebo_results$ratio), ]
placebo_results$rank <- seq_len(nrow(placebo_results))
rwanda_rank <- placebo_results$rank[placebo_results$unit == "RWA"]
p_value <- rwanda_rank / nrow(placebo_results)

write.csv(placebo_results, "results/immunization-extension-placebo.csv", row.names = FALSE)

cat("\nRwanda's placebo rank:", rwanda_rank, "of", nrow(placebo_results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(placebo_results, 6))
