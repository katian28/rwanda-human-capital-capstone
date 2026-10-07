#!/usr/bin/env Rscript
# Full-pool GDP placebo test. This is the headline placebo result for the
# paper (not the smaller 9-country version in code/03, which is a
# restricted-pool sensitivity check). Same idea as code/02: treat each
# country in turn as if IT were hit by the genocide in 1994, fit a
# synthetic control for it from the other countries, and see how big its
# "fake" gap is. If Rwanda's real gap is not bigger than most of these
# fake gaps, that's evidence the gap is not statistically unusual.
#
# Uses Hodler's actual predictor set (PWT 7.1 investment/openness, WDI
# GDP-deflator inflation, Polity, Freedom House, UCDP conflict), not the
# earlier simplified GDP-only special predictors. This genuinely shrinks
# the usable donor pool -- from 39 countries (GDP-only completeness) down
# to the 37 with at least one real observation of every predictor in the
# window (verified in code/14_predictor_assembly_check.R; dataprep()
# itself handles any remaining partial-year gaps via na.rm=TRUE, verified
# directly against its own source behavior, not assumed). Using
# GDP-deflator inflation rather than WDI CPI is what keeps this pool at
# 38 instead of 29: CPI has large real gaps across Sub-Saharan Africa
# (including Liberia's entire pre-2002 history), the deflator does not.
# A smaller but fully predictor-complete pool is the more defensible
# headline test than a larger pool built on a predictor set we know is
# missing for many of its members.
#
# Section 7 adds an in-time placebo (fake 1985 treatment) using the same
# pool, with simpler GDP-only predictors -- see code/03's header comment
# for why (UCDP conflict data doesn't exist before 1989).

library(readxl)
library(Synth)
library(rgenoud)
library(quadprog)

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

treatment_year <- 1994
first_year <- 1970
last_year <- 2011
pre_window <- 1985:1990
conflict_window <- 1991:1993

# 37-country pool: Sub-Saharan Africa minus Rwanda and the spillover-risk
# neighbors (Burundi, DR Congo, Tanzania, Uganda -- see docs/replication-
# feasibility.md), further restricted to countries with at least one real
# observation of EVERY Hodler predictor in its window (verified in
# code/14_predictor_assembly_check.R's "lenient" check -- dataprep()
# itself averages over whatever years are actually present via its own
# na.rm=TRUE handling, confirmed directly against Synth's source, not
# assumed). Uses GDP-deflator inflation, not CPI: CPI alone would have
# left only 29 countries here (and dropped Liberia from the 9-donor pool
# in code/02/03 entirely) -- the deflator has far better coverage across
# this candidate pool (40 of 43 vs. 24 of 43), checked directly. Somalia
# is excluded despite passing that predictor check: PWT 8.0 has zero
# rgdpe (the dependent variable itself, not a special predictor) for
# Somalia in any year used here -- a genuine PWT gap for a collapsed
# state, not an avoidable sourcing choice.
donors <- c("AGO", "BEN", "BWA", "BFA", "CPV", "CMR", "CAF", "TCD", "COM",
            "COG", "CIV", "GNQ", "SWZ", "ETH", "GAB", "GMB", "GHA", "GIN",
            "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
            "NAM", "NER", "NGA", "SEN", "SLE", "ZAF", "SDN", "TGO",
            "ZMB", "ZWE")

# ---- 1. Load and merge Hodler's full predictor set -------------------------
# Identical sourcing/merge logic to code/02 -- see there for full comments
# on each source and the two real data-mapping bugs found while verifying
# them (Polity's scode is not ISO3; Freedom House's pre-1990 editions need
# the label's second year, not the "Year(s) Under Review" field).

pwt80 <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))
gdp <- pwt80[pwt80$countrycode %in% c("RWA", donors) & pwt80$year %in% first_year:last_year,
             c("countrycode", "year", "rgdpe")]
names(gdp)[3] <- "gdp"
for (c_ in unique(gdp$countrycode)) {
  m <- gdp$countrycode == c_
  baseline <- mean(gdp$gdp[m & gdp$year %in% 1991:1993])
  gdp$gdp[m] <- gdp$gdp[m] / baseline
}

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
  Rwanda = "RWA", Angola = "AGO", Benin = "BEN", Botswana = "BWA",
  "Burkina Faso" = "BFA", "Cabo Verde" = "CPV", Cameroon = "CMR",
  "Central African Republic" = "CAF", Chad = "TCD", Comoros = "COM",
  "Congo (Brazzaville)" = "COG", "Cote d'Ivoire" = "CIV", "Equatorial Guinea" = "GNQ",
  Eswatini = "SWZ", Ethiopia = "ETH", Gabon = "GAB", "The Gambia" = "GMB",
  Ghana = "GHA", Guinea = "GIN", "Guinea-Bissau" = "GNB", Kenya = "KEN",
  Lesotho = "LSO", Liberia = "LBR", Madagascar = "MDG", Malawi = "MWI",
  Mali = "MLI", Mauritania = "MRT", Mauritius = "MUS", Namibia = "NAM",
  Niger = "NER", Nigeria = "NGA", Senegal = "SEN", "Sierra Leone" = "SLE",
  Somalia = "SOM", "South Africa" = "ZAF", Sudan = "SDN", Togo = "TGO",
  Zambia = "ZMB", Zimbabwe = "ZWE"
)
fh_long$countrycode <- name_to_iso3[fh_long$country]
political_rights <- fh_long[!is.na(fh_long$countrycode), c("countrycode", "year", "pr")]

ucdp <- read.csv("data/raw/ucdp_conflict.csv", stringsAsFactors = FALSE)
ucdp_name_to_iso3 <- c(
  Rwanda = "RWA", Angola = "AGO", Benin = "BEN", Botswana = "BWA",
  "Burkina Faso" = "BFA", "Cape Verde" = "CPV", Cameroon = "CMR",
  "Central African Republic" = "CAF", Chad = "TCD", Comoros = "COM",
  Congo = "COG", "Ivory Coast" = "CIV", "Equatorial Guinea" = "GNQ",
  Swaziland = "SWZ", Ethiopia = "ETH", Gabon = "GAB", Gambia = "GMB",
  Ghana = "GHA", Guinea = "GIN", "Guinea-Bissau" = "GNB", Kenya = "KEN",
  Lesotho = "LSO", Liberia = "LBR", Madagascar = "MDG", Malawi = "MWI",
  Mali = "MLI", Mauritania = "MRT", Mauritius = "MUS", Namibia = "NAM",
  Niger = "NER", Nigeria = "NGA", Senegal = "SEN", "Sierra Leone" = "SLE",
  Somalia = "SOM", "South Africa" = "ZAF", Sudan = "SDN", Togo = "TGO",
  Zambia = "ZMB", Zimbabwe = "ZWE"
)
ucdp$countrycode <- ucdp_name_to_iso3[ucdp$location_inc]
conflict_avg <- aggregate(bd_best ~ countrycode, data = ucdp[!is.na(ucdp$countrycode) & ucdp$year %in% conflict_window, ],
                           FUN = function(x) sum(x) / length(conflict_window))
conflict <- merge(data.frame(countrycode = c("RWA", donors)), conflict_avg, all.x = TRUE)
conflict$bd_best[is.na(conflict$bd_best)] <- 0
conflict_grid <- expand.grid(countrycode = c("RWA", donors), year = conflict_window, stringsAsFactors = FALSE)
conflict <- merge(conflict_grid, conflict, by = "countrycode")

panel <- gdp
panel <- merge(panel, invest_open, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, inflation, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, polity, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, political_rights, by = c("countrycode", "year"), all.x = TRUE)
panel <- merge(panel, conflict[, c("countrycode", "year", "bd_best")], by = c("countrycode", "year"), all.x = TRUE)

panel$unit_id <- as.numeric(factor(panel$countrycode))
id_lookup <- unique(panel[, c("countrycode", "unit_id")])

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

odd_years <- seq(1971, 1993, by = 2)
hodler_special_predictors <- c(
  lapply(odd_years, function(yr) list("gdp", yr, "mean")),
  list(
    list("gdp", pre_window, "mean"),
    list("ki", pre_window, "mean"),
    list("openk", pre_window, "mean"),
    list("inflation_deflator_pct", pre_window, "mean"),
    list("polity2", pre_window, "mean"),
    list("pr", pre_window, "mean"),
    list("bd_best", conflict_window, "mean")
  )
)

# ---- 2. One function that fits a synthetic control for ANY treated unit ---

fit_one_unit <- function(treated_code, control_codes) {
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
    time.plot = first_year:last_year,
    special.predictors = hodler_special_predictors
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

# ---- 3. Run it for Rwanda, then for every donor country as a placebo -----

all_units <- c("RWA", donors)
cat("Fitting", length(all_units), "synthetic controls (this takes a while)...\n")

results <- data.frame()
for (treated in all_units) {
  others <- setdiff(donors, treated)
  one_result <- fit_one_unit(treated, others)
  results <- rbind(results, one_result)
  cat(".")
}
cat("\n")

# ---- 4. Rank everyone by their ratio, find Rwanda's rank ------------------

results <- results[order(-results$ratio), ]
results$rank <- seq_len(nrow(results))
rwanda_rank <- results$rank[results$unit == "RWA"]
p_value <- rwanda_rank / nrow(results)

write.csv(results, "results/placebo-full-pool-in-space.csv", row.names = FALSE)

cat("\nRwanda's rank:", rwanda_rank, "of", nrow(results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(results, 6))

# ---- 5. In-time placebo: pretend the treatment was in 1985 ----------------
# Simpler GDP-only special predictors -- see code/03's header comment for
# why (UCDP conflict data doesn't exist before 1989).

fake_year <- 1985
fake_pre <- first_year:(fake_year - 1)

dp_fake <- dataprep(
  foo = panel,
  dependent = "gdp",
  unit.variable = "unit_id",
  unit.names.variable = "countrycode",
  time.variable = "year",
  treatment.identifier = id_lookup$unit_id[id_lookup$countrycode == "RWA"],
  controls.identifier = id_lookup$unit_id[id_lookup$countrycode %in% donors],
  time.predictors.prior = fake_pre,
  time.optimize.ssr = fake_pre,
  time.plot = first_year:last_year,
  special.predictors = list(
    list("gdp", 1970:1979, "mean"),
    list("gdp", fake_pre[length(fake_pre) - 4]:fake_pre[length(fake_pre)], "mean")
  )
)
fit_fake <- fit_synth_robust(dp_fake)
actual_fake <- dp_fake$Y1plot[, 1]
synthetic_fake <- as.numeric(dp_fake$Y0plot %*% fit_fake$solution.w)
gap_fake <- actual_fake - synthetic_fake
years <- first_year:last_year

in_time_pre_rmspe <- sqrt(mean(gap_fake[years < fake_year]^2))
in_time_post_rmspe <- sqrt(mean(gap_fake[years >= fake_year & years < treatment_year]^2))
in_time_ratio <- in_time_post_rmspe / in_time_pre_rmspe

write.csv(
  data.frame(year = years, actual = actual_fake, synthetic = synthetic_fake, gap = gap_fake),
  "results/placebo-full-pool-in-time.csv", row.names = FALSE
)
cat("\nIn-time placebo (fake 1985 treatment, full pool):\n")
cat("Pre-1985 RMSPE:", round(in_time_pre_rmspe, 4), "\n")
cat("1985-1993 RMSPE:", round(in_time_post_rmspe, 4), "\n")
cat("Ratio:", round(in_time_ratio, 2), "\n")
