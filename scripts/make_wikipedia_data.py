#!/usr/bin/env python3
"""Generate the optional Wikipedia and Wikimedia Commons material the app shows.

Only entities with a real Wikipedia section or a per-unit Commons photograph are written. The
file is deliberately incomplete: a station, unit or division absent from it gets no Wikipedia
section, rather than a repeated general paragraph.

The station histories are short, objective paraphrases of the current-station entries in
*List of historic Toronto fire stations*. The unit photographs are the Commons files whose
descriptions name the unit code. Text is CC BY-SA 4.0; each image keeps its own licence and author
in the file.
"""

import argparse
import datetime
import html
import json
import pathlib
import re
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "TorontoLiveEMSKit" / "Sources" / "TorontoLiveEMSKit" / "Resources"
PAGE = "List of historic Toronto fire stations"
PAGE_URL = "https://en.wikipedia.org/wiki/List_of_historic_Toronto_fire_stations"
WIKI_API = "https://en.wikipedia.org/w/api.php"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
TEXT_LICENCE = "CC BY-SA 4.0"

# The current station number and a phrase from the current station's address, so the parser picks
# the current hall rather than a predecessor that shares a number (314 has two entries).
STATIONS = {
    "114": "12 Canterbury",
    "131": "3135 Yonge",
    "134": "16 Montgomery",
    "226": "87 Main",
    "227": "1904 Queen",
    "311": "20 Balmoral",
    "312": "34 Yorkville",
    "314": "12 Grosvenor",
    "315": "132 Bellevue",
    "324": "840 Gerrard",
    "325": "475 Dundas",
    "342": "106 Ascot",
    "344": "240 Howland",
    "346": "CNE grounds",
    "423": "358 Keele",
    "425": "83 DeForest",
    "435": "130 Eighth",
}


# One readable paragraph per station, paraphrased from the current-station entry. The raw list
# form ("Built:", "Location:", "Main Structure:") is the source's presentation, not the app's.
DESCRIPTIONS = {
    "114": """Station 114 at 12 Canterbury Place is the second North York fire hall to carry the name Ivan M. Nelson Fire Station. The present building opened in 1989 as North York Fire Department Station 1, replacing the earlier 1942 Colonial Revival hall at 5125 Yonge Street. That building was demolished for the Empress Walk development, although its hose tower and stone entrance were preserved and incorporated into the mall.""",
    "131": """Station 131 at 3135 Yonge Street opened in 1931 as Toronto Fire Department Station 34. The two-storey, two-bay hall was built to the same plan as Station 424. In 2003 the apparatus floor was lowered and the building extensively retrofitted to accommodate a taller aerial ladder; before that work, Pumper 131 and Aerial 131 exited down a driveway onto Yonge Street, and afterward they had to climb from the lowered floor to the street.""",
    "134": """Station 134 at 16 Montgomery Avenue opened in 1932 as Toronto Fire Department Station 28. The two-storey hall was designed to resemble the houses beside it, a domestic scale that distinguishes it from the larger apparatus-focused stations of the period.""",
    "226": """Station 226 at 87 Main Street in the Upper Beaches opened in 1910-11 as Toronto Fire Department Station 22. The two-storey Romanesque Revival hall has two vehicle bays, a rear hose tower and a bay-window structure. The original two-storey wooden fire hall with a tower that stood next door was demolished after 1911.""",
    "227": """Station 227 at 1904 Queen Street East, also known as the Kew Beach Fire Hall, opened in 1905 as Toronto Fire Department Station 17. The three-storey Queen Anne Revival building has a clock tower, a single vehicle bay and a side tower; a second bay was added in 1960.""",
    "311": """Station 311 at 20 Balmoral Avenue, known as Balmoral Fire Hall, opened in 1911 as Toronto Fire Department Station 24. The three-storey Queen Anne Revival hall has two bays and retains a rear hose tower and a second-storey beam and doorway that were used to hoist hay into the loft. It was designated a National Historic Site of Canada in 1990 for its rare example of the Queen Anne Revival style.""",
    "312": """Station 312 at 34 Yorkville Avenue was built in 1877 for the Yorkville Fire Department and became Toronto Fire Department Station 10 when Yorkville was annexed in 1883. The two-storey hall is one of the city's oldest active fire stations; it has a five-storey clock tower, three bays and a coat of arms from the old Yorkville Town Hall, and it was restored in 1974.""",
    "314": """Station 314 at 12 Grosvenor Street opened in 1926 as Toronto Fire Department Station 3, succeeding a company established in 1874 at a different Yonge Street location. The two-storey, two-bay hall is also known as Pumper 314: Running the Strip.""",
    "315": """Station 315 at 132 Bellevue Avenue opened in 1878 as Toronto Fire Department Station 8, with an addition built in 1922 for Ladder 29. The two-storey hall has three bays, one from the original building, and an eight-storey clock tower. An arsonist set the tower and clock ablaze in 1972; the tower was rebuilt in 1972-73 with a replica clock. Together with Station 312, it is an example of Victorian Gothic fire-hall architecture.""",
    "324": """Station 324 at 840 Gerrard Street East opened in 1932 as Toronto Fire Department Station 12. The symmetrical two-storey hall has three apparatus bays.""",
    "325": """Station 325 at 475 Dundas Street East opened in 1954 as Toronto Fire Department Station 7. The long two-storey hall has three bays and is known as Fort Apache.""",
    "342": """Station 342 at 106 Ascot Avenue opened in 1912 as Toronto Fire Department Station 27. The two-storey hall has a single small bay; the old Station 27 next door, built in 1913, later became a semi-detached house. The station is nicknamed the Mid-Town Mob.""",
    "344": """Station 344 at 240 Howland Avenue in Davenport opened in 1910 as Toronto Fire Department Station 23. The three-storey hall has two bays and a two-storey Victorian bay-window structure, and its design is similar to that of Station 226.""",
    "346": """Station 346 at 90 Quebec Street, on the CNE grounds near the Dufferin Gates, opened in 1912 as Toronto Fire Department Station 29 and was later renumbered 31 and then 32. The two-storey hall, designed by G. W. Gouinlock, has two bays and a five-storey clock tower; it also houses Toronto EMS and Toronto Police Service facilities and remains in year-round operation as R346.""",
    "423": """Station 423 at 358 Keele Street opened in 1959 as Toronto Fire Department Station 20, replacing an 1890 hall on the same site known as West Toronto Fire Hall No. 1. The station is nicknamed West Toronto - The Junction.""",
    "425": """Station 425 at 83 DeForest Road opened in 1930 for the Village of Swansea Fire Department and joined Toronto Fire Department as Station 16 when Swansea was annexed in 1967. The single-storey, two-bay hall is designed to resemble a converted house, like Station 424.""",
    "435": """Station 435 at 130 Eighth Street opened in 1930 for the New Toronto Fire Department and became Etobicoke Fire Department Station 9 when New Toronto was annexed by Etobicoke in 1967. The two-storey hall was built in three stages, with the four-bay section the newest part; it is nicknamed R435: The Lone Wolf.""",
}

# Only files whose Commons description names the unit code are used. A generic type photograph is
# not assigned to every unit of that type.
IMAGES = {
    "P143": "File:Toronto Fire P143.jpg",
    "P332": "File:Toronto Fire Services P332.jpg",
    "S331": "File:Toronto Fire Services S331 King.jpg",
    "T333": "File:Fire engine T333 at Front Street.jpg",
    "HR332": "File:HR332 Toronto.jpg",
    "CMD10": "File:TFS Command 10.jpg",
    "CMD30": "File:TFS CMD30.jpg",
}


def read_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "TorontoLiveEMS wikipedia import"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def strip_html(value):
    value = re.sub(r"<[^>]+>", "", value or "")
    return html.unescape(value).strip()


def page_extract():
    query = {
        "action": "query",
        "prop": "extracts|revisions",
        "explaintext": "1",
        "rvprop": "ids|timestamp",
        "titles": PAGE,
        "format": "json",
    }
    data = read_json(WIKI_API + "?" + urllib.parse.urlencode(query))
    page = next(iter(data["query"]["pages"].values()))
    revisions = page.get("revisions") or [{}]
    revision = page.get("lastrevid") or revisions[0].get("revid", "")
    return page["extract"], str(revision)


def station_entries(extract, revision, retrieved):
    starts = list(re.finditer(r"(?m)^Station (\d{3})\s*$", extract))
    entries = {}
    for number, address in STATIONS.items():
        candidates = [match for match in starts if match.group(1) == number]
        chosen = None
        for match in candidates:
            following = extract[match.end() : match.end() + 1200]
            if address.lower() in following.lower():
                chosen = match
                break
        if chosen is None:
            raise SystemExit(f"no Wikipedia entry found for Station {number}")
        description = DESCRIPTIONS.get(number)
        if not description:
            raise SystemExit(f"no curated description for Station {number}")
        entries[number] = {
            "title": PAGE,
            "url": PAGE_URL + "#Station_" + number,
            "summary": description,
            "licence": TEXT_LICENCE,
            "retrieved": retrieved,
            "revision": revision,
        }
    return entries


def image_entries(retrieved):
    data = read_json(
        COMMONS_API
        + "?"
        + urllib.parse.urlencode(
            {
                "action": "query",
                "prop": "imageinfo",
                "iiprop": "url|extmetadata",
                "iiurlwidth": "960",
                "titles": "|".join(IMAGES.values()),
                "format": "json",
            }
        )
    )
    by_title = {page["title"]: page for page in data["query"]["pages"].values()}
    entries = {}
    for code, title in IMAGES.items():
        page = by_title[title]
        info = page["imageinfo"][0]
        metadata = info.get("extmetadata", {})
        licence = strip_html(metadata.get("LicenseShortName", {}).get("value"))
        author = strip_html(metadata.get("Artist", {}).get("value")) or "Unknown"
        thumb = info.get("thumburl") or info["url"]
        thumb = thumb.split("?", 1)[0]
        entries[code] = {
            "title": title,
            "url": info["descriptionurl"],
            "licence": licence,
            "retrieved": retrieved,
            "image": {
                "url": thumb,
                "pageURL": info["descriptionurl"],
                "author": author,
                "licence": licence,
            },
        }
    return entries


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out-dir", default=str(DEFAULT_OUT))
    parser.add_argument(
        "--retrieved",
        default=datetime.date.today().isoformat(),
        help="the retrieval date to record, yyyy-MM-dd (defaults to today)",
    )
    arguments = parser.parse_args()

    extract, revision = page_extract()
    stations = station_entries(extract, revision, arguments.retrieved)
    units = image_entries(arguments.retrieved)
    document = {
        "source": PAGE_URL,
        "licence": TEXT_LICENCE + " (text); images under their own licences",
        "retrieved": arguments.retrieved,
        "stations": stations,
        "units": units,
    }
    out = pathlib.Path(arguments.out_dir) / "TorontoWikipedia.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(document, separators=(",", ":"))
    out.write_text(payload, encoding="utf-8")
    print(f"  {len(stations)} stations, {len(units)} units")
    print(f"  wrote {out}: {len(payload)} bytes")


if __name__ == "__main__":
    main()
