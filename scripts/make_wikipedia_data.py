#!/usr/bin/env python3
"""Generate the optional Wikipedia and Wikimedia Commons material the app shows.

Only entities with a real Wikipedia section or a per-unit Commons photograph are written. The
file is deliberately incomplete: a station, unit or division absent from it gets no Wikipedia
section, rather than a repeated general paragraph.

The station histories are the current-station entries in *List of historic Toronto fire stations*.
The unit photographs are the Commons files whose descriptions name the unit code. Text is
CC BY-SA 4.0; each image keeps its own licence and author in the file.
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
    boundaries = [
        match.start()
        for match in re.finditer(
            r"(?m)^(?:Station \d{3}\s*$|_{2,}.*_{2,}\s*$)", extract
        )
    ]
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
        end = next((position for position in boundaries if position > chosen.start()), len(extract))
        lines = [
            line.strip()
            for line in extract[chosen.start() : end].splitlines()
            if line.strip()
            and not line.strip().startswith("Media related")
            and not line.strip().startswith("==")
        ]
        if lines and re.fullmatch(r"Station \d{3}", lines[0]):
            lines = lines[1:]
        entries[number] = {
            "title": PAGE,
            "url": PAGE_URL + "#Station_" + number,
            "extract": "\n".join(lines),
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
