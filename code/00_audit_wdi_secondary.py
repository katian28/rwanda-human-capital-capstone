#!/usr/bin/env python3
"""Reproduce the WDI secondary-enrollment availability screen.

Uses only Python's standard library and the public World Bank API. It downloads
current SE.SEC.ENRR observations, identifies Sub-Saharan African countries from
World Bank metadata, applies the project's neighbor exclusions, and prints the
coverage statistics used in the feasibility memo.
"""

import json
from urllib.parse import urlencode
from urllib.request import urlopen


API = "https://api.worldbank.org/v2"
INDICATOR = "SE.SEC.ENRR"
EXCLUDED = {"RWA", "BDI", "COD", "TZA", "UGA"}
PUBLISHED_DONORS = ["CMR", "COG", "GAB", "LBR", "LSO", "MLI", "NER", "SDN", "SEN"]


def fetch(path, **params):
    params.update(format="json", per_page=20000)
    url = f"{API}/{path}?{urlencode(params)}"
    with urlopen(url, timeout=60) as response:
        return json.load(response)


def main():
    country_payload = fetch("country", per_page=400)
    ssa = {
        row["id"]: row["name"]
        for row in country_payload[1]
        if row["region"]["id"] == "SSF"
    }
    observations = fetch(f"country/all/indicator/{INDICATOR}", date="1970:2011")
    observed = {}
    for row in observations[1]:
        if row["value"] is not None:
            observed.setdefault(row["countryiso3code"], set()).add(int(row["date"]))

    rwanda = observed["RWA"]
    pre = sorted(year for year in rwanda if year < 1994)
    post = sorted(year for year in rwanda if year >= 1994)
    eligible = sorted(set(ssa) - EXCLUDED)
    threshold = [c for c in eligible if len(observed.get(c, set()) & set(range(1970, 1994))) >= 12
                 and len(observed.get(c, set()) & set(range(1999, 2012))) >= 8]

    print("Rwanda pre-1994 observed years:", pre)
    print("Rwanda 1994-2011 observed years:", post)
    print("Eligible SSA donors:", len(eligible))
    print("Donors meeting >=12 pre and >=8 post-1998 observations:", len(threshold))

    for start in (1976, 1980, 1985):
        required = set(range(start, 1993)) | set(range(1999, 2012))
        complete = [ssa[c] for c in eligible if required <= observed.get(c, set())]
        print(f"Complete donors for {start}-1992 and 1999-2011:", complete)

    print("Published GDP donor counts (1970-1993/1994-2011):")
    for code in PUBLISHED_DONORS:
        years = observed.get(code, set())
        n_pre = len(years & set(range(1970, 1994)))
        n_post = len(years & set(range(1994, 2012)))
        print(f"  {ssa.get(code, code)} ({code}): {n_pre}/{n_post}")


if __name__ == "__main__":
    main()
