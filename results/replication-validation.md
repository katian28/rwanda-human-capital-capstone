# Published-weight GDP reconstruction

**Run date:** 9 September 2026

## Result

Using PWT 8.0 `rgdpe` with the paper's reported rounded donor weights reproduces the headline path. Using `rgdpo`, the variable named in the manuscript, does not. This indicates an apparent outcome-label inconsistency that must be checked against the author's original files.

## Benchmark comparison

- Published pre-treatment RMSPE: 0.0584; reconstructed with `rgdpe`: 0.0574; with `rgdpo`: 0.0999.
- Published 1994 gap: -0.58; reconstructed with `rgdpe`: -0.582; with `rgdpo`: -0.534.
- Published 2011 gap: approximately 0.00; reconstructed with `rgdpe`: -0.004; with `rgdpo`: 0.431.

The small remaining differences are consistent with applying donor weights rounded to three decimals; the displayed weights sum to 1.001. Exact author weights and code were not available for this run.

## Interpretation

This completes the first replication checkpoint: the published headline result can be reconstructed from the exact PWT release and reported weights. It does not yet reproduce the optimization that generated those weights or the placebo inference. Those are the next replication stages.
