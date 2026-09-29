# Does the hc placebo result survive at hc's true (5-year) frequency?

**Run date:** 28 September 2026

code/07 fits the synthetic control on all 24 pre-treatment years of PWT's `hc`, but `results/hc-interpolation-check.md` established that hc is a deterministic interpolation of Barro-Lee's five-year schooling data -- so those 24 years are really ~5 independent data points, repeated for every donor alike. This script reruns the identical design, but restricts predictor matching, SSR optimization, and RMSPE evaluation to only the true measurement years, to see whether the result is real or an artifact of fake annual resolution.

**True pre-treatment years used:** 1970, 1975, 1980, 1985, 1990 (5 points, vs. 24 in code/07)
**True post-treatment years used:** 1995, 2000, 2005, 2010 (4 points, vs. 18 in code/07)

## Main result

Pre-treatment RMSPE: 0.00000000 (code/07, at fake annual resolution: 0.00020)
Average post-treatment gap: 0.059

## Placebo result

Rwanda's rank: 3 of 28
p-value (rank / total units): 0.107 (code/07, at fake annual resolution: 0.036)

## Interpretation

Restricting to hc's true measurement years does not rescue the concern -- it trades one artifact for a worse one. The pre-treatment RMSPE does not loosen at the honest frequency; it gets even tighter (essentially machine precision, 6.5e-12), because with only 5 real matching points and a 27-country donor pool, an almost-exact convex-combination match is close to guaranteed for whichever country is 'treated', regardless of any real similarity. This is the synthetic control method's own well-known interpolation-bias failure mode (too many free donor weights relative to too few predictors), not evidence of a good counterfactual.

Rwanda's placebo rank also slips from 1st of 28 (p=0.036) at fake annual resolution to 3 of 28 (p=0.107) at the true frequency -- no longer clearing the conventional 10% threshold. Between the trivial-fit problem and the weaker placebo rank, the hc extension's apparent significance is fragile to exactly how the same underlying five real data points are used. It should be presented in the paper as a measurement-limitation finding (PWT's hc index cannot support this kind of annual-resolution inference either as fabricated annual data or at its true frequency), not as a substantive human-capital result.
