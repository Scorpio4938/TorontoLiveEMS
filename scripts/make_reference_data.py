#!/usr/bin/env python3
"""Generate the reference data the app ships: fire stations, police divisions, police facilities,
and fire units.

Four published City of Toronto sources, four small derived files, and one script. The files are
committed; this script is the only thing that writes them, so a value in the app can always be
traced to a published row and the date it was read.

Stations
--------
*Fire Facility Locations* on the City's Open Data portal:

    https://open.toronto.ca/dataset/fire-station-locations/

The published GeoJSON carries 85 rows: 84 fire stations and one operations training site at
25 Old Eglinton Ave. The training site has no station number, so the import filters on the
published `TYPE_DESC` rather than counting rows. A row is a station when the City says it is.

Divisions
---------
*Police Boundaries*:

    https://open.toronto.ca/dataset/police-boundaries/

Nineteen features, each with the division number in `AREA_LONG_CODE`. The geometry is not
shipped: no screen draws a division boundary, and a polygon nothing reads is a second copy of a
published shape waiting to drift. What the app needs is the number, so that is what the file has.

Facilities
----------
*Police Facility Locations*:

    https://open.toronto.ca/dataset/police-facility-locations/

Twenty-six facilities, of which sixteen are a division's own address. A facility belongs to a
division when its published name is `<two digits> Division`; `55 Substation` is a different
building and is not 55 Division. A division with no such row is left out, so the app can show no
address rather than an empty one.

Units
-----
A capture of the live fire feed:

    https://www.toronto.ca/data/fire/livecad.xml

The City publishes no list of apparatus. It publishes the units dispatched at the moment someone
reads the feed, so the units list is *ours*: the codes seen in one capture, each named from the
City's own legend and placed at a station when its digits are one of the 84 published station
numbers. The file records the moment the feed itself says it was built, as well as the date this
script read it.

The legend is read from `DispatchedUnit.swift`, which is where the app already keeps the City's
legend verbatim. Reading it here rather than typing it a second time means the names in the file
and the names a screen derives cannot disagree.

Licence
-------
Every published source here is Open Government Licence – Toronto. The licence and the retrieval
date travel in each generated file, because the file is what travels into the app.

Usage
-----
    python3 scripts/make_reference_data.py

Add `--stations`, `--divisions`, `--facilities` or `--capture` to read a saved copy instead of the
published URL.
That is for regenerating from a file when the network is unavailable, not a second source: the
URLs below are the only published ones this script knows.

No third-party libraries. The CKAN downloads are plain requests and the live feed is XML that
`xml.etree` reads.
"""

import argparse
import datetime
import json
import pathlib
import re
import urllib.request
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "TorontoLiveEMSKit" / "Sources" / "TorontoLiveEMSKit" / "Resources"
DEFAULT_LEGEND = (
    ROOT / "TorontoLiveEMSKit" / "Sources" / "TorontoLiveEMSKit" / "DispatchedUnit.swift"
)

STATIONS_URL = (
    "https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/"
    "a6ce5495-8e2b-421a-ab11-964569416f31/resource/"
    "4a9bb96b-da5e-4c67-aaf4-3f8f4f311430/download/fire-station-locations-4326.geojson"
)
DIVISIONS_URL = (
    "https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/"
    "6ff875e3-7c26-4abe-8fb2-afe7b2519ba2/resource/"
    "52fac153-c14b-437f-8121-75fbfa162532/download/police-boundaries-data-4326.geojson"
)
FACILITIES_URL = (
    "https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/"
    "9aeefa17-27e8-4dd9-b74d-80f7f9eb85ac/resource/"
    "c0176e24-8b76-4bb2-96fa-61cc1af2a065/download/police-facility-locations-4326.geojson"
)
UNITS_URL = "https://www.toronto.ca/data/fire/livecad.xml"

LICENCE = "Open Government Licence – Toronto"

STATION_TYPE = "Fire Station"


# --- reading the published sources ----------------------------------------------------------


def read(path_or_url):
    """The bytes at a published URL, or in a saved copy of one."""
    if path_or_url.startswith(("http://", "https://")):
        request = urllib.request.Request(
            path_or_url,
            headers={"User-Agent": "TorontoLiveEMS reference-data import"},
        )
        with urllib.request.urlopen(request, timeout=90) as response:
            return response.read()
    return pathlib.Path(path_or_url).read_bytes()


def document(path_or_url):
    return json.loads(read(path_or_url))


def text(value):
    """A published value, or nothing when the value is a placeholder for nothing.

    The City uses a blank, a space and the word `None` in the same columns. All three mean the
    station houses no such office, which is the same rule the app's parsers apply to the feeds:
    no letter and no digit means no value.
    """
    if value is None:
        return None
    published = str(value).strip()
    if not published or published.lower() == "none":
        return None
    if not any(character.isalnum() for character in published):
        return None
    return published


def required_text(value, field):
    """A value the generated file cannot be correct without.

    `text()` is for the office columns, where a blank is an answer. A station's address,
    municipality and ward name are not optional: writing `null` would produce a file the app
    refuses to read, and the failure belongs here, beside the published row, rather than at launch.
    """
    published = text(value)
    if not published:
        raise SystemExit(f"a station has no {field}")
    return published


def coordinate_of(geometry):
    """The one point a station's geometry carries, in degrees.

    The published file uses `MultiPoint` for every station, with one coordinate in it. A Point
    would mean the same thing; anything else is a shape this data does not use and should not be
    guessed at.
    """
    kind = geometry.get("type")
    coordinates = geometry.get("coordinates")
    if kind == "Point":
        longitude, latitude = coordinates
    elif kind == "MultiPoint":
        if len(coordinates) != 1:
            raise SystemExit(f"a station has {len(coordinates)} points, not one")
        longitude, latitude = coordinates[0]
    else:
        raise SystemExit(f"a station has {kind} geometry, not a point")
    return {"latitude": round(latitude, 6), "longitude": round(longitude, 6)}


def stations_from(published, retrieved):
    """Every published fire station, with the fields the app can name."""
    rows = [
        feature
        for feature in published.get("features", [])
        if feature.get("properties", {}).get("TYPE_DESC") == STATION_TYPE
    ]
    if not rows:
        raise SystemExit(f"the published station file has no {STATION_TYPE!r} rows")

    stations = []
    for feature in rows:
        properties = feature["properties"]
        offices = []
        for column in ("PUBLIC_ED_OFFICE", "FIRE_PREV_OFFICE", "FIRE_OTHER"):
            office = text(properties.get(column))
            if office and office not in offices:
                offices.append(office)
        stations.append(
            {
                "number": int(properties["STATION"]),
                "address": required_text(properties.get("ADDRESS"), "address"),
                "municipality": required_text(
                    properties.get("MUNICIPALITY_NAME"), "municipality"
                ),
                "yearBuilt": int(properties["YEAR_BUILD"]),
                "ward": {
                    "number": int(properties["WARD"]),
                    "name": required_text(properties.get("WARD_NAME"), "ward name"),
                },
                "offices": offices,
                "coordinate": coordinate_of(feature["geometry"]),
            }
        )

    stations.sort(key=lambda station: station["number"])
    return {
        "source": STATIONS_URL,
        "licence": LICENCE,
        "retrieved": retrieved,
        "stations": stations,
    }


def divisions_from(published, retrieved):
    """The 19 division numbers, and nothing about their shapes."""
    numbers = []
    for feature in published.get("features", []):
        number = text(feature.get("properties", {}).get("AREA_LONG_CODE"))
        if number and number not in numbers:
            numbers.append(number)
    if not numbers:
        raise SystemExit("the published division file has no division numbers")
    numbers.sort()
    return {
        "source": DIVISIONS_URL,
        "licence": LICENCE,
        "retrieved": retrieved,
        "divisions": [{"number": number} for number in numbers],
    }


def police_facilities_from(published, division_numbers, retrieved):
    """The facility rows that are divisions, keyed by the division they are.

    The published file has 26 facilities — headquarters, collision reporting centres, the college,
    marine and mounted units — and only some of them are a division's own address. A facility is a
    division's when its published name is `<two digits> Division`; `55 Substation` is a different
    facility at a different address and is not 55 Division's row. Divisions with no such row are
    simply absent, which is what the division page needs to know to show no address.
    """
    facilities = {}
    for feature in published.get("features", []):
        properties = feature.get("properties", {})
        name = text(properties.get("FACILITY"))
        if not name:
            continue
        match = re.fullmatch(r"(\d{1,2})\s+Division", name, re.IGNORECASE)
        if not match:
            continue
        division = f"{int(match.group(1)):02d}"
        if division not in division_numbers:
            raise SystemExit(f"a facility names division {division}, which is not published")
        if division in facilities:
            raise SystemExit(f"two facilities claim division {division}")
        facilities[division] = {
            "division": division,
            "address": required_text(properties.get("ADDRESS"), "facility address"),
            "postalCode": required_text(properties.get("POSTAL_CODE"), "postal code"),
            "coordinate": coordinate_of(feature["geometry"]),
        }

    if not facilities:
        raise SystemExit("the published facility file has no division facilities")

    return {
        "source": FACILITIES_URL,
        "licence": LICENCE,
        "retrieved": retrieved,
        "facilities": [facilities[number] for number in sorted(facilities)],
    }


def legend_from_swift(path):
    """The City's legend, in the order the app keeps it.

    `DispatchedUnit.legend` is one `Legend(code: "P", name: "Pumper")` per line. Reading the
    Swift file is deliberately unglamorous: the alternative is a second copy of the legend in
    Python, and two copies of a published vocabulary is one copy too many.
    """
    source = pathlib.Path(path).read_text(encoding="utf-8")
    entries = re.findall(r'Legend\(code:\s*"([^"]+)",\s*name:\s*"([^"]+)"\)', source)
    if not entries:
        raise SystemExit(f"no legend entries in {path}")
    return entries


def trailing_digits(code):
    index = len(code)
    while index > 0 and code[index - 1].isdigit():
        index -= 1
    return code[index:]


def units_from(capture, station_numbers, legend, retrieved):
    """The codes one capture dispatched, named and placed by the app's own rules."""
    root = ET.fromstring(capture)
    captured_at = text(root.findtext("update_from_db_time"))
    if not captured_at:
        raise SystemExit("the capture has no update_from_db_time")

    codes = []
    seen = set()
    for event in root.findall("event"):
        roster = event.findtext("units_disp") or ""
        for token in roster.split(","):
            code = token.strip()
            if code and code not in seen:
                seen.add(code)
                codes.append(code)
    if not codes:
        raise SystemExit("the capture dispatched no units")

    # Longest legend code first, so `CMD1` reads as Command Vehicle rather than Chief and
    # `PL231` as Platform rather than Pumper. The Swift legend is already in that order, but
    # sorting here means the file does not depend on the order it happens to be written in.
    ordered_legend = sorted(legend, key=lambda entry: len(entry[0]), reverse=True)

    units = []
    for code in sorted(codes):
        name = next((name for prefix, name in ordered_legend if code.startswith(prefix)), None)
        digits = trailing_digits(code)
        station = int(digits) if digits else None
        if station is not None and station not in station_numbers:
            station = None
        units.append({"code": code, "name": name, "station": station})

    return {
        "source": UNITS_URL,
        "licence": LICENCE,
        "retrieved": retrieved,
        "capturedAt": captured_at,
        "units": units,
    }


# --- writing the derived files ---------------------------------------------------------------


def write(path, document):
    payload = json.dumps(document, separators=(",", ":"))
    pathlib.Path(path).write_text(payload, encoding="utf-8")
    print(f"  wrote {path}: {len(payload)} bytes")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--stations", help="a saved copy of the station GeoJSON")
    parser.add_argument("--divisions", help="a saved copy of the division GeoJSON")
    parser.add_argument("--facilities", help="a saved copy of the facility GeoJSON")
    parser.add_argument("--capture", help="a saved copy of the live feed XML")
    parser.add_argument("--legend", default=str(DEFAULT_LEGEND), help="the Swift legend to read")
    parser.add_argument("--out-dir", default=str(DEFAULT_OUT))
    parser.add_argument(
        "--retrieved",
        default=datetime.date.today().isoformat(),
        help="the retrieval date to record, yyyy-MM-dd (defaults to today)",
    )
    arguments = parser.parse_args()

    out_dir = pathlib.Path(arguments.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    stations = stations_from(
        document(arguments.stations or STATIONS_URL), arguments.retrieved
    )
    divisions = divisions_from(
        document(arguments.divisions or DIVISIONS_URL), arguments.retrieved
    )
    division_numbers = {division["number"] for division in divisions["divisions"]}
    facilities = police_facilities_from(
        document(arguments.facilities or FACILITIES_URL),
        division_numbers,
        arguments.retrieved,
    )
    legend = legend_from_swift(arguments.legend)
    station_numbers = {station["number"] for station in stations["stations"]}
    units = units_from(
        read(arguments.capture or UNITS_URL), station_numbers, legend, arguments.retrieved
    )

    print(f"  {len(stations['stations'])} stations")
    print(f"  {len(divisions['divisions'])} divisions")
    print(f"  {len(facilities['facilities'])} division facilities")
    named = sum(1 for unit in units["units"] if unit["name"])
    placed = sum(1 for unit in units["units"] if unit["station"])
    print(
        f"  {len(units['units'])} units from the capture at {units['capturedAt']}: "
        f"{named} named, {placed} at a station"
    )

    write(out_dir / "TorontoFireStations.json", stations)
    write(out_dir / "TorontoPoliceDivisions.json", divisions)
    write(out_dir / "TorontoPoliceFacilities.json", facilities)
    write(out_dir / "TorontoFireUnits.json", units)


if __name__ == "__main__":
    main()
