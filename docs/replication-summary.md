# GDP replication: bottom line

**The path reconstructs convincingly. The claim that it's statistically unusual does not hold up at the correct donor-pool size.** Both things are true at once; neither should be read as cancelling the other out.

## The path replicates

Independently re-estimated from scratch — donor weights re-derived with no reference to the published values — Rwanda's 1994 GDP gap comes out to **-0.555**, next to the published **-0.58**. Pre-treatment fit is close too: RMSPE **0.0555** versus published **0.0584**. Reconstructing the published path from the exact PWT 8.0 release and Hodler's own reported weights gets even closer (1994 gap -0.582, pre-treatment RMSPE 0.0574) — see `results/replication-validation.md`. The "GDP fell by roughly half in 1994 and took about seventeen years to recover" story holds up.

One real, worth-stating divergence: the independently re-estimated donor weights concentrate almost entirely on Cameroon (0.498) and Senegal (0.461), while the published weights spread more evenly across all nine donors (`results/gdp-reestimated-weights.csv`). A similar aggregate path can emerge from a different weight vector — a known feature of the method (multiple near-equally-good solutions), not evidence either estimation is wrong.

## The significance does not

At the full, properly-sized 39-country Sub-Saharan Africa donor pool — not a smaller, more flattering one — **Rwanda's gap ranks 31st of 40 (p = 0.775)**. Not statistically unusual. Several placebo countries, led by Equatorial Guinea (post-1994 oil boom, pre-treatment RMSPE 0.098 but post-treatment RMSPE 39.4), show far larger deviations for reasons that have nothing to do with the genocide. See `results/placebo-full-pool-in-space.csv`, `figures/placebo-ranking-full-pool.png`.

A smaller 9-country pool (the only countries with non-zero published weights) gives a better-looking rank 3 of 10 (p = 0.30) — still not a strong result, but noticeably more favorable than the honest test. **This project reports the full-pool result as the headline, not the smaller pool's more favorable number**, and applying Hodler's own documented placebo-exclusion rule to the full-pool test doesn't rescue it either (rank 31 of 37, p = 0.838 — the rule filters bad pre-treatment fits, not the large unrelated post-treatment volatility, like Equatorial Guinea's, that actually drives the ranking). See `results/placebo-restricted.md`, `results/placebo-hodler-rule.md`.

## Why this number moved during the project, and in which direction

Mid-project, a real numerical bug was found and fixed in how this project's code was using the `Synth` package's `genoud` optimizer (`kernlab::ipop`, the package's inner solver, could silently return a suboptimal result near sparse donor-weight solutions). Fixing it — verified against `Synth`'s actual documented algorithm (Abadie, Diamond & Hainmueller 2011, *JSS* 42(13)), not just patched ad hoc — moved the full-pool placebo result from an earlier p = 0.53 to the final p = 0.775. **More rigor produced a weaker result, not a stronger one.** That direction of travel is itself evidence the final number is the honest one: the earlier, more favorable result was an artifact of under-optimized code, not a real effect that the fix destroyed. Full derivation: `code/02_reestimate_gdp_weights.R` header comment; process log: `process-log/2026-09-29-synth-fix-and-extension-redesign.md`.

## One-line version

The path reconstructs; the statistical-significance claim does not survive a properly-sized placebo test; both are reported, and the weaker, less convenient number is the one treated as the headline.
