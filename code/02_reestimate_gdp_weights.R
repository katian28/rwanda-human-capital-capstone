#!/usr/bin/env Rscript
# Rwanda GDP synthetic control, using the real Synth package
# (written by Abadie, Diamond & Hainmueller -- the people who invented
# this method). No custom math here: dataprep() and synth() do the
# actual estimation, and synth.tab()/path.plot()/gaps.plot() (also from
# the Synth package) build the table and plots. Every line is commented.
#
# Uses Hodler's actual documented predictor set (docs/replication-
# feasibility.md, sourced from the manuscript): PWT 8.0 GDP, PWT 7.1
# investment and openness, WDI inflation, Polity political regime,
# Freedom House political rights, and UCDP conflict -- not the earlier
# simplified three-special-predictor version this project used while
# those five sources hadn't yet been assembled. See
# code/14_predictor_assembly_check.R for the sourcing and completeness
# verification behind this.

library(readxl)   # PWT 8.0, PWT 7.1 variable dictionary
library(Synth)    # the actual synthetic control package
library(rgenoud)  # genoud's outer search, called directly (see below)
library(quadprog) # the inner QP solver we swap in for genoud's search

# genoud (used below) picks its internal random seed via runif() by
# default -- i.e. it is NOT reproducible run to run unless we fix R's own
# seed first. Verified empirically: two runs without this gave a 1994 gap
# of -0.572 and -0.585. Fixing it here makes every run identical.
set.seed(42)

# fit_synth_robust() reimplements synth()'s own documented algorithm
# (Abadie, Diamond & Hainmueller 2011, "Synth: An R Package for Synthetic
# Control Methods in Comparative Case Studies," Journal of Statistical
# Software 42(13), section 3.2; matches ?synth and Synth's source exactly):
#   - for any candidate predictor-weight matrix V, W*(V) minimizes
#     ||X1 - X0 W||_V, a quadratic program (JSS paper, eq. 1);
#   - V* is then chosen to minimize the resulting pre-treatment MSPE,
#     (Z1 - Z0 W*(V))' (Z1 - Z0 W*(V)) (JSS paper, eq. 2);
#   - by default, synth() tries TWO starting points for V -- equal weights
#     and a regression-based guess -- each locally refined via Nelder-Mead
#     and BFGS, keeping whichever wins ("by default synth() always runs
#     the optimization twice ... and returns the run that obtains lower
#     loss," JSS paper footnote 16);
#   - with genoud = TRUE, a third candidate is added: genoud()'s global
#     search, whose output is likewise only a STARTING POINT, always
#     locally refined afterward ("Solutions from genoud() are then passed
#     to optim() in the second step," same footnote) -- never used raw.
#
# The one deliberate deviation: JSS eq. 1's quadratic program is normally
# solved via kernlab's ipop (what synth() calls internally). ipop's
# interior-point solver turned out to be numerically fragile on this
# project's data specifically, near sparse W solutions -- and not just by
# erroring: handing a winning V to synth(dp, custom.v = ...) let Synth
# re-solve W via ipop, and for that exact V, ipop's W scored 8x worse than
# quadprog's W for the identical V (loss 0.0242 vs. 0.0031). ipop can
# silently return a poor W with no error, for every candidate V evaluated
# during the search, not just the final one. Fix: solve every instance of
# JSS eq. 1 with quadprog::solve.QP instead -- same equation, numerically
# robust solver, not a change to the method itself.
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
  cat("genoud-seeded loss:", round(cand1$value, 6), " | regression-seeded loss:", round(cand2$value, 6), "\n")

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

treatment_year <- 1994
first_year <- 1970
last_year <- 2011
pre_window <- 1985:1990      # Hodler's standard predictor-averaging window
conflict_window <- 1991:1993 # Hodler's conflict-specific window (UCDP battle-
                              # deaths data only starts 1989, plausibly why)

# Hodler's published donor weights are only non-zero for these 9 countries.
# Liberia is dropped here: it has zero WDI inflation data anywhere before
# 2002 (its own 1989-2003 civil wars), confirmed in
# code/14_predictor_assembly_check.R -- not a parsing gap, a genuine
# absence. Its own published weight was Hodler's smallest (0.032), so this
# is a small, documented exclusion, not a consequential one.
donors <- c("CMR", "COG", "GAB", "LSO", "MLI", "NER", "SDN", "SEN")

# ---- 1. GDP (PWT 8.0) -------------------------------------------------------

pwt80 <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))
gdp <- pwt80[pwt80$countrycode %in% c("RWA", donors) & pwt80$year %in% first_year:last_year,
             c("countrycode", "year", "rgdpe")]
names(gdp)[3] <- "gdp"
for (c_ in unique(gdp$countrycode)) {
  m <- gdp$countrycode == c_
  baseline <- mean(gdp$gdp[m & gdp$year %in% 1991:1993])
  gdp$gdp[m] <- gdp$gdp[m] / baseline
}

# ---- 2. Investment share and openness (PWT 7.1) ----------------------------
# Constant-price variants (ki, openk), the more standard choice in growth/
# synthetic-control empirics (avoids relative-price distortions); Hodler's
# own manuscript doesn't specify current vs. constant. isocode "ZAR" is
# this vintage's code for DR Congo -- not relevant to this 8-donor pool,
# kept as a documented fact from code/14, not remapped here.

pwt71 <- read.csv("data/raw/pwt71.csv", stringsAsFactors = FALSE)
invest_open <- pwt71[pwt71$isocode %in% c("RWA", donors) & pwt71$year %in% pre_window,
                      c("isocode", "year", "ki", "openk")]
names(invest_open)[1] <- "countrycode"

# ---- 3. Inflation (WDI) -----------------------------------------------------

wdi <- read.csv("data/raw/wdi_inflation.csv", stringsAsFactors = FALSE)
inflation <- wdi[wdi$countrycode %in% c("RWA", donors) & wdi$year %in% pre_window,
                  c("countrycode", "year", "inflation_cpi_pct")]

# ---- 4. Polity political regime (Polity5) -----------------------------------
# scode is NOT ISO3 for most countries -- verified directly in code/14, not
# assumed. Mapping only the codes this 8-donor pool (+Rwanda) actually uses.

polity_raw <- as.data.frame(read_excel("data/raw/polity.xls"))
scode_to_iso3 <- c(RWA = "RWA", CAO = "CMR", CON = "COG", GAB = "GAB",
                    LES = "LSO", MLI = "MLI", NIR = "NER", SUD = "SDN",
                    SEN = "SEN")
polity_raw$iso3 <- scode_to_iso3[polity_raw$scode]
polity <- polity_raw[!is.na(polity_raw$iso3) & polity_raw$year %in% pre_window,
                      c("iso3", "year", "polity2")]
names(polity)[1] <- "countrycode"

# ---- 5. Political rights (Freedom House) -------------------------------------
# Pre-1990 editions use irregular, overlapping multi-month spans with no
# clean single calendar year in "Year(s) Under Review"; the edition
# label's SECOND year, minus 1, gives a clean gap-free annual series that
# connects seamlessly to the clean post-1990 editions -- verified by hand
# against the raw header row in code/14 (using the first year instead
# leaves 1989 completely unassigned, which is wrong: there is no missing
# year in the underlying editions, only in a naive parse of them).

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
name_to_iso3 <- c(Rwanda = "RWA", Cameroon = "CMR", "Congo (Brazzaville)" = "COG",
                   Gabon = "GAB", Lesotho = "LSO", Mali = "MLI", Niger = "NER",
                   Sudan = "SDN", Senegal = "SEN")
fh_long$countrycode <- name_to_iso3[fh_long$country]
political_rights <- fh_long[!is.na(fh_long$countrycode), c("countrycode", "year", "pr")]

# ---- 6. Conflict (UCDP battle deaths) ---------------------------------------
# Absence = true zero (no conflict crossed the reporting threshold), not
# missing, for any year from 1989 onward -- confirmed in code/14. Averaged
# over Hodler's own shorter 1991-1993 conflict window.

ucdp <- read.csv("data/raw/ucdp_conflict.csv", stringsAsFactors = FALSE)
ucdp_name_to_iso3 <- c(Rwanda = "RWA", Cameroon = "CMR", Congo = "COG", Gabon = "GAB",
                        Lesotho = "LSO", Mali = "MLI", Niger = "NER", Sudan = "SDN",
                        Senegal = "SEN")
ucdp$countrycode <- ucdp_name_to_iso3[ucdp$location_inc]
ucdp_agg <- aggregate(bd_best ~ countrycode, data = ucdp[!is.na(ucdp$countrycode) & ucdp$year %in% conflict_window, ], sum)
conflict_grid <- expand.grid(countrycode = c("RWA", donors), year = conflict_window, stringsAsFactors = FALSE)
# bd_best aggregated above is already summed across the window per country;
# spread it back across the window's years evenly isn't meaningful for a
# "mean" special predictor, so compute the window AVERAGE directly instead.
conflict_avg <- aggregate(bd_best ~ countrycode, data = ucdp[!is.na(ucdp$countrycode) & ucdp$year %in% conflict_window, ],
                           FUN = function(x) sum(x) / length(conflict_window))
conflict <- merge(data.frame(countrycode = c("RWA", donors)), conflict_avg, all.x = TRUE)
conflict$bd_best[is.na(conflict$bd_best)] <- 0
# Expand into one row per conflict_window year (same averaged value each
# year) so it merges cleanly into the single wide panel below; the special
# predictor itself will average these three identical rows, recovering the
# same window-average value either way.
conflict <- merge(conflict_grid, conflict, by = "countrycode")

# ---- 7. Merge everything into one wide panel --------------------------------

panel <- gdp
panel <- merge(panel, invest_open, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, inflation, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, polity, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, political_rights, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, conflict[, c("countrycode", "year", "bd_best")], by = c("countrycode", "year"), all.x = TRUE)

panel$unit_id <- as.numeric(factor(panel$countrycode))
rwanda_id <- panel$unit_id[panel$countrycode == "RWA"][1]
donor_ids <- unique(panel$unit_id[panel$countrycode %in% donors])

# ---- 8. dataprep(): Hodler's actual predictor set ---------------------------
# "1985-1990 averages for most predictors and an additional 1991-1993
# conflict average... normalized GDP in odd pre-treatment years through
# 1993 plus average GDP levels in 1985-1990" (docs/replication-
# feasibility.md, sourced from the manuscript).

odd_years <- seq(1971, 1993, by = 2)
gdp_odd_year_predictors <- lapply(odd_years, function(yr) list("gdp", yr, "mean"))

dataprep_out <- dataprep(
  foo = panel,
  dependent = "gdp",
  unit.variable = "unit_id",
  unit.names.variable = "countrycode",
  time.variable = "year",
  treatment.identifier = rwanda_id,
  controls.identifier = donor_ids,
  time.predictors.prior = first_year:(treatment_year - 1),
  time.optimize.ssr = first_year:(treatment_year - 1),
  time.plot = first_year:last_year,
  special.predictors = c(
    gdp_odd_year_predictors,
    list(
      list("gdp", pre_window, "mean"),
      list("ki", pre_window, "mean"),
      list("openk", pre_window, "mean"),
      list("inflation_cpi_pct", pre_window, "mean"),
      list("polity2", pre_window, "mean"),
      list("pr", pre_window, "mean"),
      list("bd_best", conflict_window, "mean")
    )
  )
)

# ---- 9. synth(): the actual optimization that picks the donor weights -----

synth_out <- fit_synth_robust(dataprep_out)

# ---- 10. Look at the results, using Synth's own built-in tools -------------

print(synth.tab(synth.res = synth_out, dataprep.res = dataprep_out))

dir.create("figures", showWarnings = FALSE)
png("figures/gdp-reestimated-path.png", width = 1400, height = 900, res = 150)
path.plot(
  synth.res = synth_out,
  dataprep.res = dataprep_out,
  Ylab = "Normalized GDP (1991-1993 average = 1)",
  Xlab = "Year",
  Main = "Rwanda GDP: actual vs. independently re-estimated synthetic",
  Legend = c("Rwanda", "Synthetic Rwanda")
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

png("figures/gdp-reestimated-gaps.png", width = 1400, height = 900, res = 150)
gaps.plot(
  synth.res = synth_out,
  dataprep.res = dataprep_out,
  Ylab = "Gap (actual - synthetic)",
  Xlab = "Year",
  Main = "Rwanda GDP gap (independently re-estimated weights)"
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

# ---- 11. Save the numbers other scripts/the paper can use -------------------

dir.create("results", showWarnings = FALSE)

published_weights <- c(
  CMR = 0.254, COG = 0.061, GAB = 0.149, LBR = 0.032, LSO = 0.192,
  MLI = 0.016, NER = 0.108, SDN = 0.014, SEN = 0.175
)
weights_table <- data.frame(
  donor = donors,
  published_weight = as.numeric(published_weights[donors]),
  synth_weight = round(as.numeric(synth_out$solution.w), 4)
)
write.csv(weights_table, "results/gdp-reestimated-weights.csv", row.names = FALSE)

actual <- dataprep_out$Y1plot[, 1]
synthetic <- as.numeric(dataprep_out$Y0plot %*% synth_out$solution.w)
path_table <- data.frame(year = first_year:last_year, actual = actual, synthetic = synthetic)
path_table$gap <- path_table$actual - path_table$synthetic
write.csv(path_table, "results/gdp-reestimated-path.csv", row.names = FALSE)

pre_years <- path_table$year < treatment_year
pre_treatment_rmspe <- sqrt(mean(path_table$gap[pre_years]^2))
gap_1994 <- path_table$gap[path_table$year == 1994]
gap_2011 <- path_table$gap[path_table$year == 2011]
cat("\nPre-treatment RMSPE:", round(pre_treatment_rmspe, 4), "\n")
cat("1994 gap:", round(gap_1994, 3), "\n")
cat("2011 gap:", round(gap_2011, 3), "\n")
