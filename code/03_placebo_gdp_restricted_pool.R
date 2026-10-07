#!/usr/bin/env Rscript
# Placebo tests for the 9-country donor pool (the published-weight
# countries only). This is a restricted-pool SENSITIVITY check, not the
# headline placebo result: see code/04_placebo_gdp_full_pool.R for the
# full 37-country test, which is the one to trust.
#
# In-space placebo: reassign the "treatment" to each donor country in
# turn and see how big a gap it gets by chance, compared to Rwanda's.
# Uses Hodler's actual predictor set (see code/02), since this is the
# real 1994 treatment year the predictor windows were designed around.
#
# In-time placebo: pretend the genocide happened in 1985 instead of 1994,
# and check whether a spurious gap opens up before it actually did. Uses
# the simpler GDP-only special predictors instead: Hodler's conflict
# predictor (UCDP battle deaths) has no data before 1989, so it cannot be
# shifted back to a fake 1985 treatment's pre-treatment window at all,
# and shifting only some of the five external predictors while dropping
# others would not be a clean, defensible mirror of the real design. This
# is a secondary robustness check, not the headline, so the simpler
# specification is an acceptable, clearly documented trade-off here.

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

# All 9 of Hodler's published donors are usable: Liberia only looked
# unusable with WDI CPI inflation (zero coverage before 2002, its own
# 1989-2003 civil wars); GDP-deflator inflation covers it fully -- see
# code/14_predictor_assembly_check.R.
donors <- c("CMR", "COG", "GAB", "LBR", "LSO", "MLI", "NER", "SDN", "SEN")

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
scode_to_iso3 <- c(RWA = "RWA", CAO = "CMR", CON = "COG", GAB = "GAB",
                    LBR = "LBR", LES = "LSO", MLI = "MLI", NIR = "NER",
                    SUD = "SDN", SEN = "SEN")
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
name_to_iso3 <- c(Rwanda = "RWA", Cameroon = "CMR", "Congo (Brazzaville)" = "COG",
                   Gabon = "GAB", Liberia = "LBR", Lesotho = "LSO", Mali = "MLI",
                   Niger = "NER", Sudan = "SDN", Senegal = "SEN")
fh_long$countrycode <- name_to_iso3[fh_long$country]
political_rights <- fh_long[!is.na(fh_long$countrycode), c("countrycode", "year", "pr")]

ucdp <- read.csv("data/raw/ucdp_conflict.csv", stringsAsFactors = FALSE)
ucdp_name_to_iso3 <- c(Rwanda = "RWA", Cameroon = "CMR", Congo = "COG", Gabon = "GAB",
                        Liberia = "LBR", Lesotho = "LSO", Mali = "MLI", Niger = "NER",
                        Sudan = "SDN", Senegal = "SEN")
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

# ---- 2. In-space placebo fit, using Hodler's full predictor set -----------

fit_in_space <- function(treated_code, control_codes) {
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
  data.frame(year = first_year:last_year, actual = actual, synthetic = synthetic, gap = actual - synthetic)
}

rmspe <- function(gap, mask) sqrt(mean(gap[mask]^2))

run_in_space_unit <- function(treated) {
  pool <- setdiff(donors, treated)
  res <- fit_in_space(treated, pool)
  pre_r <- rmspe(res$gap, res$year < treatment_year)
  post_r <- rmspe(res$gap, res$year >= treatment_year)
  list(unit = treated, res = res, ratio = post_r / pre_r, pre_rmspe = pre_r, post_rmspe = post_r)
}

rwanda_run <- run_in_space_unit("RWA")
placebo_runs <- lapply(donors, run_in_space_unit)

in_space <- do.call(rbind, lapply(c(list(rwanda_run), placebo_runs), function(r) {
  data.frame(unit = r$unit, pre_rmspe = r$pre_rmspe, post_rmspe = r$post_rmspe, ratio = r$ratio)
}))
in_space <- in_space[order(-in_space$ratio), ]
in_space$rank <- seq_len(nrow(in_space))
rwanda_rank <- in_space$rank[in_space$unit == "RWA"]
p_value <- rwanda_rank / nrow(in_space)
write.csv(in_space, "results/placebo-restricted-in-space.csv", row.names = FALSE)

# ---- 3. In-time placebo: pretend the treatment was in 1985 ----------------
# Simpler GDP-only special predictors -- see header comment for why.

fit_in_time <- function(treated_code, control_codes, pre_years, plot_years) {
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
    time.predictors.prior = pre_years,
    time.optimize.ssr = pre_years,
    time.plot = plot_years,
    special.predictors = list(
      list("gdp", pre_years[1]:(pre_years[1] + 9), "mean"),
      list("gdp", (pre_years[1] + 10):(pre_years[1] + 19), "mean"),
      list("gdp", tail(pre_years, 4), "mean")
    )
  )

  fit <- fit_synth_robust(dp)
  actual <- dp$Y1plot[, 1]
  synthetic <- as.numeric(dp$Y0plot %*% fit$solution.w)
  data.frame(year = plot_years, actual = actual, synthetic = synthetic, gap = actual - synthetic)
}

fake_year <- 1985
fake_pre <- first_year:(fake_year - 1)
plot_years <- first_year:last_year
in_time <- fit_in_time("RWA", donors, fake_pre, plot_years)
in_time_pre_rmspe <- rmspe(in_time$gap, in_time$year < fake_year)
in_time_post_rmspe <- rmspe(in_time$gap, in_time$year >= fake_year & in_time$year < treatment_year)
in_time_ratio <- in_time_post_rmspe / in_time_pre_rmspe
write.csv(in_time, "results/placebo-restricted-in-time.csv", row.names = FALSE)

# ---- 4. Report --------------------------------------------------------------

lines <- c(
  "# Placebo tests, 9-country donor pool (Hodler's published donors, all 9)",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "This is a restricted-pool sensitivity check, not the headline placebo result -- see `results/placebo-full-pool-in-space.csv` / `code/04_placebo_gdp_full_pool.R` for the full 37-country test. In-space placebo uses Hodler's full documented predictor set (PWT 7.1 investment/openness, WDI inflation, Polity, Freedom House, UCDP conflict); the in-time placebo uses simpler GDP-only predictors since UCDP conflict data doesn't exist before 1989 and cannot be shifted back to a fake 1985 treatment's pre-period.",
  "",
  "## In-space placebo",
  "",
  "| Rank | Unit | Pre-RMSPE | Post-RMSPE | Ratio |",
  "|------|------|-----------|------------|-------|",
  paste0(
    "| ", in_space$rank, " | ", in_space$unit, " | ",
    sprintf("%.4f", in_space$pre_rmspe), " | ",
    sprintf("%.4f", in_space$post_rmspe), " | ",
    sprintf("%.2f", in_space$ratio), " |",
    collapse = "\n"
  ),
  "",
  sprintf("**Rwanda's rank: %d of %d (p = %.3f).**", rwanda_rank, nrow(in_space), p_value),
  "",
  "## In-time placebo (fake treatment year: 1985)",
  "",
  sprintf("- Pre-1985 RMSPE: %.4f", in_time_pre_rmspe),
  sprintf("- 1985-1993 (placebo post) RMSPE: %.4f", in_time_post_rmspe),
  sprintf("- Ratio: %.2f", in_time_ratio)
)
writeLines(lines, "results/placebo-restricted.md")

# ---- 5. Figures -------------------------------------------------------------

png("figures/placebo-restricted-in-space.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
all_gaps <- c(rwanda_run$res$gap, unlist(lapply(placebo_runs, function(r) r$res$gap)))
plot(
  NA, xlim = range(first_year:last_year), ylim = range(all_gaps),
  xlab = "Year", ylab = "Gap (actual - synthetic)",
  main = "In-space placebo (9-country pool, Hodler's predictor set)"
)
for (r in placebo_runs) lines(r$res$year, r$res$gap, col = "#9CA3AF", lwd = 1.2)
lines(rwanda_run$res$year, rwanda_run$res$gap, col = "#DC2626", lwd = 3)
abline(v = treatment_year, lty = 3, lwd = 2, col = "#111827")
abline(h = 0, lty = 1, lwd = 1, col = "#00000055")
legend(
  "bottomleft", legend = c("Rwanda", "Placebo donors", "1994 genocide"),
  col = c("#DC2626", "#9CA3AF", "#111827"), lty = c(1, 1, 3), lwd = c(3, 1.2, 2), bty = "n"
)
mtext("Restricted 9-country sensitivity check -- see code/04 for the full-pool headline test", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

png("figures/placebo-restricted-in-time.png", width = 1600, height = 950, res = 170)
par(mar = c(6.3, 4.8, 3.5, 1.5), family = "sans")
plot(
  in_time$year, in_time$actual, type = "l", lwd = 3, col = "#111827",
  xlab = "Year", ylab = "Normalized GDP (1991-1993 average = 1)",
  main = "In-time placebo: fake 1985 treatment (9-country pool)",
  ylim = range(c(in_time$actual, in_time$synthetic))
)
lines(in_time$year, in_time$synthetic, lwd = 3, lty = 2, col = "#2563EB")
abline(v = fake_year, lty = 3, lwd = 2, col = "#D97706")
abline(v = treatment_year, lty = 3, lwd = 2, col = "#DC2626")
legend(
  "topleft", legend = c("Rwanda", "Synthetic Rwanda (fit on 1970-1984)", "Fake 1985 treatment", "Real 1994 genocide"),
  col = c("#111827", "#2563EB", "#D97706", "#DC2626"), lty = c(1, 2, 3, 3), lwd = c(3, 3, 2, 2), bty = "n", cex = 0.8
)
mtext("Weights fit on 1970-1984 only; gap checked for 1985-1993 before the real treatment", side = 1, line = 4.8, cex = 0.75, col = "#4B5563")
dev.off()

cat(paste(lines, collapse = "\n"), "\n")
