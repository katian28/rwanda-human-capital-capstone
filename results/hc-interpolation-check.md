# Is PWT hc annual data, or interpolated from Barro-Lee's five-year data?

**Run date:** 25 September 2026

## Check 1: five-year regime shifts

Rwanda's hc year-over-year change, 1971-1993:

| Year | hc | Yearly change |
|------|-----|---------------|
| 1970 | 1.167410 | -- |
| 1971 | 1.176064 | 0.008653 |
| 1972 | 1.184781 | 0.008717 |
| 1973 | 1.193563 | 0.008782 |
| 1974 | 1.202410 | 0.008847 |
| 1975 | 1.211323 | 0.008913 |
| 1976 | 1.219233 | 0.007911 |
| 1977 | 1.227196 | 0.007962 |
| 1978 | 1.235210 | 0.008014 |
| 1979 | 1.243277 | 0.008067 |
| 1980 | 1.251396 | 0.008119 |
| 1981 | 1.258044 | 0.006648 |
| 1982 | 1.264727 | 0.006683 |
| 1983 | 1.271445 | 0.006718 |
| 1984 | 1.278199 | 0.006754 |
| 1985 | 1.284989 | 0.006790 |
| 1986 | 1.294889 | 0.009900 |
| 1987 | 1.304866 | 0.009977 |
| 1988 | 1.314919 | 0.010053 |
| 1989 | 1.325050 | 0.010131 |
| 1990 | 1.335259 | 0.010209 |
| 1991 | 1.352329 | 0.017071 |
| 1992 | 1.369618 | 0.017289 |
| 1993 | 1.387128 | 0.017510 |

The same pattern (nearly constant within each five-year block, distinct shift at each five-year boundary) holds for Cameroon, Zambia, Mali, and Senegal as well -- see `results/hc-interpolation-check.csv` for all five countries. This is not a Rwanda-specific artifact.

## Check 2: the 2010-2011 boundary

hc is IDENTICAL between 2010 and 2011 for every country checked (RWA, CMR, ZMB, MLI, SEN): the 2011 value is the 2010 value carried forward, not real data. For comparison, Rwanda's rgdpe changes normally over the same years (12056.90 in 2010, 13147.93 in 2011) -- this freeze is specific to hc, not a general PWT-vintage issue.

## Why this matters

A 24-year pre-treatment window (1970-1993) is effectively ~5 real data points per country, not 24 independent ones, since every donor country's hc is built the same way. Fitting a weighted average of 27 donor countries to match a series with that few real degrees of freedom is close to guaranteed to look near-perfect almost regardless of which country is treated -- consistent with 5 of the 27 donors showing an even tighter pre-treatment fit than Rwanda (see code/07 placebo output).

The 2010-2011 freeze also means the apparent 'plateau' in the post-treatment gap (figures/hc-extension-gaps.png) is partly mechanical: the 2011 data point adds no independent information over 2010, for Rwanda or any donor. The post-treatment RMSPE in code/07 effectively double-counts the 2010 gap once.

This does not necessarily invalidate the human-capital placebo result (in-space ranking partially self-corrects, since every unit's pre-treatment fit is inflated the same mechanical way), but it does mean a tight pre-treatment fit on hc does not validate the counterfactual the way Abadie's method assumes for a genuinely high-frequency outcome, and the true post-treatment window is closer to 17 informative years than 18.
