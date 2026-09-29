# Immunization coverage (DTP3/MCV1) feasibility check

**Run date:** 29 September 2026

Checked as a candidate replacement for the human-capital extension after PWT's `hc` index (fabricated annual resolution) and WDI secondary enrollment (missing exactly 1994-1998) both failed. Source: WHO/UNICEF WUENIC, administrative-report data, not survey-smoothed -- see `docs/source-register.md`.

## Rwanda, 1980-2011

DTP3 coverage: 1981=17%, 1982=38%, 1983=59%, 1984=55%, 1985=50%, 1986=87%, 1987=88%, 1988=80%, 1989=82%, 1990=84%, 1991=91%, 1992=85%, 1993=83%, 1994=23%, 1995=83%, 1996=89%, 1997=73%, 1998=79%, 1999=85%, 2000=90%, 2001=77%, 2002=88%, 2003=96%, 2004=89%, 2005=95%, 2006=99%, 2007=97%, 2008=97%, 2009=97%, 2010=97%, 2011=97%.

**No missing years.** Unlike WDI enrollment (missing 1994-1998 entirely), Rwanda's DTP3 series is complete through the genocide, and shows a real crisis signature -- a sharp drop in 1994 followed by recovery the very next year -- rather than a flat interpolated line.

## Donor pool (Sub-Saharan Africa, excluding Rwanda and spillover-risk neighbors)

38 of 43 candidate donors have complete, gap-free DTP3 coverage starting in 1990 or earlier: AGO, BEN, BFA, BWA, CAF, CIV, CMR, COG, COM, CPV, ETH, GAB, GHA, GIN, GMB, GNB, GNQ, KEN, LSO, MDG, MLI, MOZ, MRT, MUS, MWI, NER, NGA, SDN, SEN, SOM, STP, SWZ, SYC, TCD, TGO, ZAF, ZMB, ZWE.

Excluded (late start, post-1990, or internal gaps): ERI, LBR, NAM, SLE, SSD.

## Verdict

Passes the balanced-panel screen that killed the previous two candidates. Genuinely annual, administratively-reported data, no gap during the exact crisis years, and a large enough donor pool to run a full-pool placebo test analogous to code/04. Caveat to disclose in the paper: WUENIC does targeted interpolation for isolated missing country/year cells in its published methodology -- a much smaller intervention than hc's wholesale annual fabrication, but not zero, and worth stating plainly.
