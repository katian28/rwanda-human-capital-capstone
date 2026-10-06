#!/usr/bin/env Rscript
# Robustness check for the immunization extension (code/12): does the
# result depend on Somalia?
#
# code/12's main fit put 39% of the synthetic control's weight on
# Somalia, by far the largest single weight -- and Somalia's own
# 1991-1993 DTP3 baseline was unusually low (~21%) and roughly doubled by
# 2009-2011 for reasons entirely about its own post-1991 civil war and
# partial recovery, unrelated to Rwanda. That's a plausible driver of a
# meaningful share of the extension's post-2000 gap. This is the
# immunization extension's version of what Equatorial Guinea was for the
# GDP placebo (code/04) -- a legitimate donor whose own volatility can
# dominate a result. Unlike the GDP case, here it's worth actually
# re-fitting without that donor, not just noting it, since it directly
# supplies the counterfactual rather than just appearing as a placebo
# outlier.
#
# This is a full re-fit excluding Somalia from the donor pool entirely
# (not a post-hoc filter of code/12's results, which would not change
# the other units' own synthetic controls or placebo donor pools).
# Otherwise identical to code/12 in every respect -- same fit_synth_robust,
# same special predictors, same window.

library(Synth)
library(rgenoud)
library(quadprog)

set.seed(42)

# fit_synth_robust() -- identical to code/02/03/04/07/10/12. See code/02
# for the full derivation and citations.
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

dtp3 <- read.csv("data/raw/who_dtp3_coverage.csv", stringsAsFactors = FALSE)
names(dtp3) <- c("country_name", "countrycode", "year", "dtp3")

# ---- 2. Build the donor pool -- SAME as code/12, plus SOM excluded --------

ssa_all <- c(
  "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD", "COM",
  "COD", "COG", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB", "GHA",
  "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT", "MUS",
  "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE", "SOM",
  "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE"
)
excluded <- c("BDI", "COD", "TZA", "UGA", "SOM")  # SOM added for this check
candidates <- setdiff(ssa_all, c("RWA", excluded))

treatment_year <- 1994
first_year <- 1981
last_year <- 2011
outcome_var <- "dtp3"

coverage <- dtp3[dtp3$countrycode %in% candidates & dtp3$year %in% first_year:last_year, ]
complete_years <- tapply(!is.na(coverage[[outcome_var]]), coverage$countrycode, sum)
donors <- names(complete_years)[complete_years == length(first_year:last_year)]
cat(length(donors), "donors have complete DTP3 coverage (Somalia excluded),", first_year, "-", last_year, "\n")

# ---- 3. Build the panel (Rwanda + all donors) ------------------------------
# NOT normalized -- see code/12 for why: DTP3 is already a common 0-100%
# scale across countries, and dividing a bounded percentage by its own
# baseline creates a ceiling/floor asymmetry that plausibly contributed to
# Somalia's outsized weight in the normalized version in the first place.

panel <- dtp3[dtp3$countrycode %in% c("RWA", donors) & dtp3$year %in% first_year:last_year,
              c("countrycode", "year", outcome_var)]
names(panel)[3] <- "coverage"

panel$unit_id <- as.numeric(factor(panel$countrycode))
id_lookup <- unique(panel[, c("countrycode", "unit_id")])

# ---- 4. Fit Rwanda's synthetic control (the main result) ------------------

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
  special.predictors = list(
    list("coverage", 1981:1985, "mean"),
    list("coverage", 1986:1989, "mean"),
    list("coverage", 1990:1993, "mean")
  )
)

synth_main <- fit_synth_robust(dp_main)

print(synth.tab(synth.res = synth_main, dataprep.res = dp_main))

dir.create("figures", showWarnings = FALSE)
png("figures/immunization-no-somalia-path.png", width = 1400, height = 900, res = 150)
path.plot(
  synth.res = synth_main,
  dataprep.res = dp_main,
  Ylab = "DTP3 immunization coverage (%)",
  Xlab = "Year",
  Main = "Rwanda immunization coverage: actual vs. synthetic (Somalia excluded)",
  Legend = c("Rwanda", "Synthetic Rwanda")
)
abline(v = treatment_year, lty = 3, col = "red")
dev.off()

dir.create("results", showWarnings = FALSE)
actual_main <- dp_main$Y1plot[, 1]
synthetic_main <- as.numeric(dp_main$Y0plot %*% synth_main$solution.w)
path_table <- data.frame(year = first_year:last_year, actual = actual_main, synthetic = synthetic_main)
path_table$gap <- path_table$actual - path_table$synthetic
write.csv(path_table, "results/immunization-no-somalia-path.csv", row.names = FALSE)

weights_table <- data.frame(donor = donors, weight = round(as.numeric(synth_main$solution.w), 4))
write.csv(weights_table, "results/immunization-no-somalia-weights.csv", row.names = FALSE)

pre_rmspe_main <- sqrt(mean(path_table$gap[path_table$year < treatment_year]^2))
post_gap_main <- path_table$gap[path_table$year >= treatment_year]
cat("\nMain result (Somalia excluded) -- pre-treatment RMSPE:", round(pre_rmspe_main, 5), "\n")
cat("1994 gap:", round(path_table$gap[path_table$year == 1994], 3), "\n")
cat("Average post-treatment gap:", round(mean(post_gap_main), 3), "\n")
cat("2011 gap:", round(path_table$gap[path_table$year == 2011], 3), "\n")

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
    special.predictors = list(
      list("coverage", 1981:1985, "mean"),
      list("coverage", 1986:1989, "mean"),
      list("coverage", 1990:1993, "mean")
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
cat("\nFitting", length(all_units), "synthetic controls for the placebo test (Somalia excluded)...\n")

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

write.csv(placebo_results, "results/immunization-no-somalia-placebo.csv", row.names = FALSE)

cat("\nRwanda's placebo rank (Somalia excluded):", rwanda_rank, "of", nrow(placebo_results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(placebo_results, 6))
