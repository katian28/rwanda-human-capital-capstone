# Independent weight re-estimation

**Run date:** 19 September 2026

## Method

Outcome-only synthetic control: donor weights (non-negative, summing to 1) are chosen by quadratic programming to minimize squared prediction error on Rwanda's normalized `rgdpe` path over the pre-treatment window (1970-1993). No auxiliary predictor characteristics are used in this pass; see the header of `code/02_reestimate_weights.R` for what a full covariate-matched version would add.

## Donor weight comparison

| Donor | Published | Re-estimated |
|-------|-----------|--------------|
| CMR | 0.254 | 0.461 |
| COG | 0.061 | 0.000 |
| GAB | 0.149 | 0.053 |
| LBR | 0.032 | 0.025 |
| LSO | 0.192 | 0.016 |
| MLI | 0.016 | 0.000 |
| NER | 0.108 | 0.106 |
| SDN | 0.014 | 0.168 |
| SEN | 0.175 | 0.170 |

## Fit comparison

- Pre-treatment RMSPE: published weights 0.0574; re-estimated weights 0.0421.
- 1994 gap: published weights -0.582; re-estimated weights -0.578.
- 2011 gap: published weights -0.004; re-estimated weights -0.018.

## Interpretation

An independently optimized donor pool achieves pre-treatment fit at least as good as the published weights by construction (the optimizer minimizes exactly this objective), which is expected and not itself evidence of a stronger result. What matters is whether the *donor composition* is similar and whether the *post-treatment gap* remains close to the published finding under an independent optimization. See the table and 1994/2011 gaps above for that comparison.

**Not yet done (flagged as follow-up, not required for this checkpoint):** re-estimating with the full predictor set Hodler used (PWT 7.1 investment/openness, WDI inflation, Polity IV, Freedom House political rights, UCDP conflict events, 1985-1990 averages) rather than outcome-only matching.
