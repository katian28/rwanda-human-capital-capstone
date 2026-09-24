# Is PWT hc annual data, or interpolated from Barro-Lee's five-year data?

**Run date:** 24 September 2026

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

## Finding

The yearly change is nearly constant within each five-year block (1971-1975, 1976-1980, 1981-1985, 1986-1990, 1991-1993), and shifts distinctly at each five-year boundary -- exactly Barro-Lee's observation grid. This confirms PWT's hc is a deterministic transform of Barro-Lee schooling data, interpolated between five-year points, not genuinely annual information.

## Why this matters for code/07 (human-capital extension)

A 24-year pre-treatment window (1970-1993) is effectively ~5 real data points per country, not 24 independent ones, since every donor country's hc is built the same way. Fitting a weighted average of 27 donor countries to match a series with that few real degrees of freedom is close to guaranteed to look near-perfect almost regardless of which country is treated -- consistent with 5 of the 27 donors showing an even tighter pre-treatment fit than Rwanda (see code/07 placebo output).

This does not necessarily invalidate the human-capital placebo result (in-space ranking partially self-corrects, since every unit's pre-treatment fit is inflated the same mechanical way), but it does mean a tight pre-treatment fit on hc does not validate the counterfactual the way Abadie's method assumes for a genuinely high-frequency outcome. The post-treatment gap itself may also be partly shaped by how the interpolation behaved for a country with disrupted underlying data during the study period, not by a real annual human-capital trajectory.
