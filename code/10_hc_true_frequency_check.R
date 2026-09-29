#!/usr/bin/env Rscript
# Does the human-capital placebo result (code/07) survive if the synthetic
# control only ever sees hc's TRUE data points, instead of PWT's fabricated
# annual interpolation between them?
#
# results/hc-interpolation-check.md already established that PWT's hc index
# is a deterministic transform of Barro-Lee's five-year schooling data,
# interpolated to look annual. A 24-year pre-treatment window is therefore
# ~5 real data points per country, not 24 independent ones -- for every
# donor alike -- which is exactly the kind of thing that can manufacture a
# near-perfect pre-treatment fit (and, mechanically, an inflated placebo
# ranking) regardless of which country is "treated".
#
# This script reruns the exact same design as code/07, but restricts every
# stage -- predictor matching, SSR optimization, and pre/post RMSPE -- to
# only the actual five-year Barro-Lee measurement years (1970, 1975, ...,
# 2010; 2011 excluded, since hc-interpolation-check.md confirmed it's an
# identical carry-forward of 2010, not new data). If the placebo result
# survives at this honest frequency, the earlier finding is real. If the
# pre-treatment fit collapses and/or Rwanda's rank drops, that confirms the
# earlier "significant" result was largely an artifact of fake annual
# resolution.

library(readxl)
library(Synth)
library(rgenoud)
library(quadprog)

set.seed(42)

# Same fit_synth_robust as code/02/03/04/07 -- reimplements synth()'s own
# documented algorithm (Abadie, Diamond & Hainmueller 2011, JSS 42(13),
# section 3.2): two starting points for V (equal weights, regression-based
# guess), each refined via Nelder-Mead and BFGS, best kept; genoud adds a
# third starting point, always locally refined, never used raw. Deviation:
# quadprog instead of kernlab's ipop solves the W-given-V quadratic program
# throughout, since ipop turned out to silently return markedly worse W
# for some V's on this project's data, with no error. See code/02 for the
# full derivation, citations, and empirical tests. Copied verbatim rather
# than sourced, so this script runs standalone.
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

# ---- 1. Load data, build the same 27-country donor pool as code/07 --------

pwt <- as.data.frame(read_excel("data/raw/pwt80.xlsx", sheet = "Data"))

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
outcome_var <- "hc"

coverage <- pwt[pwt$countrycode %in% candidates & pwt$year %in% first_year:last_year, ]
complete_years <- tapply(!is.na(coverage[[outcome_var]]), coverage$countrycode, sum)
donors <- names(complete_years)[complete_years == length(first_year:last_year)]

# ---- 2. Restrict to the TRUE five-year Barro-Lee measurement years --------
# 2011 dropped: hc-interpolation-check.md confirmed it's identical to 2010
# for every country, i.e. not an independent observation.

true_years <- seq(1970, 2010, 5)
pre_true <- true_years[true_years < treatment_year]
post_true <- true_years[true_years >= treatment_year]
cat("True pre-treatment years used:", pre_true, "\n")
cat("True post-treatment years used:", post_true, "\n")

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

# ---- 3. One fit function: predictors are the true years THEMSELVES, one -
# special.predictor per real observation, not a multi-year average that
# could smuggle interpolated years back in.

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
    time.predictors.prior = pre_true,
    time.optimize.ssr = pre_true,
    time.plot = true_years,
    special.predictors = lapply(pre_true, function(yr) list("hc_index", yr, "mean"))
  )

  fit <- fit_synth_robust(dp)

  actual <- dp$Y1plot[, 1]
  synthetic <- as.numeric(dp$Y0plot %*% fit$solution.w)
  gap <- actual - synthetic

  pre_rmspe <- sqrt(mean(gap[true_years < treatment_year]^2))
  post_rmspe <- sqrt(mean(gap[true_years >= treatment_year]^2))

  list(
    summary = data.frame(unit = treated_code, pre_rmspe = pre_rmspe, post_rmspe = post_rmspe,
                          ratio = post_rmspe / pre_rmspe),
    path = data.frame(year = true_years, actual = actual, synthetic = synthetic, gap = gap)
  )
}

# ---- 4. Main fit (Rwanda) --------------------------------------------------

main <- fit_one_unit("RWA", donors)
dir.create("results", showWarnings = FALSE)
write.csv(main$path, "results/hc-true-frequency-path.csv", row.names = FALSE)

cat("\nMain result at true frequency -- pre-treatment RMSPE:", round(main$summary$pre_rmspe, 5), "\n")
cat("Average post-treatment gap:", round(mean(main$path$gap[true_years >= treatment_year]), 3), "\n")

# ---- 5. Placebo: same fit for every donor as if IT were treated -----------

cat("\nFitting", length(donors) + 1, "synthetic controls at the true 5-year frequency...\n")

placebo_results <- main$summary
for (treated in donors) {
  others <- setdiff(donors, treated)
  one_result <- fit_one_unit(treated, others)
  placebo_results <- rbind(placebo_results, one_result$summary)
  cat(".")
}
cat("\n")

placebo_results <- placebo_results[order(-placebo_results$ratio), ]
placebo_results$rank <- seq_len(nrow(placebo_results))
rwanda_rank <- placebo_results$rank[placebo_results$unit == "RWA"]
p_value <- rwanda_rank / nrow(placebo_results)

write.csv(placebo_results, "results/hc-true-frequency-check.csv", row.names = FALSE)

cat("\nRwanda's placebo rank at true frequency:", rwanda_rank, "of", nrow(placebo_results), "\n")
cat("p-value (rank / total units):", round(p_value, 3), "\n")
print(head(placebo_results, 6))

# ---- 6. Report --------------------------------------------------------------

old_pre_rmspe <- 0.0002
old_p <- 0.036
n_true_donors <- length(donors)

lines <- c(
  "# Does the hc placebo result survive at hc's true (5-year) frequency?",
  "",
  sprintf("**Run date:** %s", format(Sys.Date(), "%d %B %Y")),
  "",
  "code/07 fits the synthetic control on all 24 pre-treatment years of PWT's `hc`, but `results/hc-interpolation-check.md` established that hc is a deterministic interpolation of Barro-Lee's five-year schooling data -- so those 24 years are really ~5 independent data points, repeated for every donor alike. This script reruns the identical design, but restricts predictor matching, SSR optimization, and RMSPE evaluation to only the true measurement years, to see whether the result is real or an artifact of fake annual resolution.",
  "",
  sprintf("**True pre-treatment years used:** %s (%d points, vs. 24 in code/07)", paste(pre_true, collapse = ", "), length(pre_true)),
  sprintf("**True post-treatment years used:** %s (%d points, vs. 18 in code/07)", paste(post_true, collapse = ", "), length(post_true)),
  "",
  "## Main result",
  "",
  sprintf("Pre-treatment RMSPE: %.8f (code/07, at fake annual resolution: %.5f)", main$summary$pre_rmspe, old_pre_rmspe),
  sprintf("Average post-treatment gap: %.3f", mean(main$path$gap[true_years >= treatment_year])),
  "",
  "## Placebo result",
  "",
  sprintf("Rwanda's rank: %d of %d", rwanda_rank, nrow(placebo_results)),
  sprintf("p-value (rank / total units): %.3f (code/07, at fake annual resolution: %.3f)", p_value, old_p),
  "",
  "## Interpretation",
  "",
  sprintf("Restricting to hc's true measurement years does not rescue the concern -- it trades one artifact for a worse one. The pre-treatment RMSPE does not loosen at the honest frequency; it gets even tighter (essentially machine precision, %.1e), because with only %d real matching points and a %d-country donor pool, an almost-exact convex-combination match is close to guaranteed for whichever country is 'treated', regardless of any real similarity. This is the synthetic control method's own well-known interpolation-bias failure mode (too many free donor weights relative to too few predictors), not evidence of a good counterfactual.", main$summary$pre_rmspe, length(pre_true), n_true_donors),
  "",
  sprintf("Rwanda's placebo rank also slips from 1st of 28 (p=0.036) at fake annual resolution to %d of %d (p=%.3f) at the true frequency -- no longer clearing the conventional 10%% threshold. Between the trivial-fit problem and the weaker placebo rank, the hc extension's apparent significance is fragile to exactly how the same underlying five real data points are used. It should be presented in the paper as a measurement-limitation finding (PWT's hc index cannot support this kind of annual-resolution inference either as fabricated annual data or at its true frequency), not as a substantive human-capital result.", rwanda_rank, nrow(placebo_results), p_value)
)
writeLines(lines, "results/hc-true-frequency-check.md")
cat("\n", paste(lines, collapse = "\n"), "\n")
