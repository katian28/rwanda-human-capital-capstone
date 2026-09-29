#!/usr/bin/env Rscript
# Human-capital extension. Same two steps as the GDP version (code/02 and
# code/04): first fit Rwanda's synthetic control and look at the gap,
# then run the same fit for every donor country as a placebo to see how
# unusual Rwanda's gap really is.

library(readxl)   # to read the PWT 8.0 Excel file
library(Synth)    # the actual synthetic control package
library(rgenoud)  # genoud's outer search, called directly (see below)
library(quadprog) # the inner QP solver we swap in for genoud's search

# genoud (used below) picks its internal random seed via runif() by
# default -- fixing R's own seed here makes every run identical. See
# code/02 for the empirical check that found this.
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

pwt <- read_excel("data/raw/pwt80.xlsx", sheet = "Data")
pwt <- as.data.frame(pwt)

# ---- 2. Build the 27-country donor pool -----------------------------------
# Same Sub-Saharan Africa candidate list as the GDP version, but kept only
# if the country has complete "hc" (human capital index) data, not rgdpe.

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
first_year <- 1970
last_year <- 2011
outcome_var <- "hc"  # PWT human-capital index, not rgdpe

coverage <- pwt[pwt$countrycode %in% candidates & pwt$year %in% first_year:last_year, ]
complete_years <- tapply(!is.na(coverage[[outcome_var]]), coverage$countrycode, sum)
donors <- names(complete_years)[complete_years == length(first_year:last_year)]
cat(length(donors), "donors have complete hc coverage\n")

# ---- 3. Build and normalize the panel (Rwanda + all donors) ---------------

panel <- pwt[pwt$countrycode %in% c("RWA", donors) & pwt$year %in% first_year:last_year,
             c("countrycode", "year", outcome_var)]
names(panel)[3] <- "hc_index"

for (country in unique(panel$countrycode)) {
  is_this_country <- panel$countrycode == country
  baseline <- mean(panel$hc_index[is_this_country & panel$year %in% 1991:1993])
  panel$hc_index[is_this_country] <- panel$hc_index[is_this_country] / baseline
}

panel$unit_id <- as.numeric(factor(panel$countrycode))
id_lookup <- unique(panel[, c("countrycode", "unit_id")])

# ---- 4. Fit Rwanda's synthetic control (the main result) ------------------

rwanda_id <- id_lookup$unit_id[id_lookup$countrycode == "RWA"]
donor_ids <- id_lookup$unit_id[id_lookup$countrycode %in% donors]

dp_main <- dataprep(
  foo = panel,
  dependent = "hc_index",
  unit.variable = "unit_id",
  unit.names.variable = "countrycode",
  time.variable = "year",
  treatment.identifier = rwanda_id,
  controls.identifier = donor_ids,
  time.predictors.prior = first_year:(treatment_year - 1),
  time.optimize.ssr = first_year:(treatment_year - 1),
  time.plot = first_year:last_year,
  special.predictors = list(
    list("hc_index", 1970:1979, "mean"),
    list("hc_index", 1980:1989, "mean"),
    list("hc_index", 1990:1993, "mean")
  )
)

synth_main <- fit_synth_robust(dp_main)

print(synth.tab(synth.res = synth_main, dataprep.res = dp_main))

dir.create("figures", showWarnings = FALSE)
png("figures/hc-extension-path.png", width = 1400, height = 900, res = 150)
path.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "Normalized human capital index (1991-1993 average = 1)",
  Xlab = "Year",
  Main = "Rwanda human capital: actual vs. synthetic",
  Legend = c("Rwanda", "Synthetic Rwanda")
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

png("figures/hc-extension-gaps.png", width = 1400, height = 900, res = 150)
gaps.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "Gap (actual - synthetic)",
  Xlab = "Year",
  Main = "Rwanda human capital gap"
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

dir.create("results", showWarnings = FALSE)
actual_main <- dp_main$Y1plot[, 1]
synthetic_main <- as.numeric(dp_main$Y0plot %*% synth_main$solution.w)
path_table <- data.frame(year = first_year:last_year, actual = actual_main, synthetic = synthetic_main)
path_table$gap <- path_table$actual - path_table$synthetic
write.csv(path_table, "results/hc-extension-path.csv", row.names = FALSE)

weights_table <- data.frame(donor = donors, weight = round(as.numeric(synth_main$solution.w), 4))
write.csv(weights_table, "results/hc-extension-weights.csv", row.names = FALSE)

pre_rmspe_main <- sqrt(mean(path_table$gap[path_table$year < treatment_year]^2))
post_gap_main <- path_table$gap[path_table$year >= treatment_year]
cat("\nMain result -- pre-treatment RMSPE:", round(pre_rmspe_main, 5), "\n")
cat("Average post-treatment gap:", round(mean(post_gap_main), 3), "\n")

# ---- 5. Placebo test: run the same fit for every donor as if IT were treated

fit_one_unit <- function(treated_code, control_codes) {
  treated_id <- id_lookup$unit_id[id_lookup$countrycode == treated_code]
  control_ids <- id_lookup$unit_id[id_lookup$countrycode %in% control_codes]

  dp <- dataprep(
    foo = panel,
    dependent = "hc_index",
    unit.variable = "unit_id",
    unit.names.variable = "countrycode",
    time.variable = "year",
    treatment.identifier = treated_id,
    controls.identifier = control_ids,
    time.predictors.prior = first_year:(treatment_year - 1),
    time.optimize.ssr = first_year:(treatment_year - 1),
    time.plot = first_year:last_year,
    special.predictors = list(
      list("hc_index", 1970:1979, "mean"),
      list("hc_index", 1980:1989, "mean"),
      list("hc_index", 1990:1993, "mean")
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

write.csv(placebo_results, "results/hc-extension-placebo.csv", row.names = FALSE)

cat("\nRwanda's placebo rank:", rwanda_rank, "of", nrow(placebo_results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(placebo_results, 6))
