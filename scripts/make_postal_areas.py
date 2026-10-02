"""Generate the Toronto forward-sortation-area shapes the map draws.

An FSA is what the City publishes for a medical incident — `M6K`, not an address — so the map
draws the FSA's area rather than a pin. The area comes from Statistics Canada's boundary file,
clipped to Toronto and simplified, because there is no API for it: MapKit has no postal
boundary of any kind, and the City's feed carries the code and nothing else.

Source
------
2021 Census — Forward sortation area boundary file, Statistics Canada:

    https://www12.statcan.gc.ca/census-recensement/2021/geo/sip-pis/boundary-limites/files-fichiers/lfsa000b21a_e.zip

Licence: Open Government Licence – Canada. Attribution is required, and the generated file
carries it, because the file is what travels into the app.

The download is 162 MB zipped and 297 MB extracted, so it is not in this repository and must
not be. This script takes the extracted files and writes the small derived file that is. Only
the derived file is committed.

Why this script reads the .prj
------------------------------
The shapefile is projected — NAD83 / Statistics Canada Lambert — so its coordinates are metres,
not degrees, and a map needs degrees. The projection parameters are read from the `.prj` that
ships with the file rather than written down here, because a projection copied from elsewhere
is a fact nobody re-checks.

Usage
-----
    python3 scripts/make_postal_areas.py \
        --shp /path/to/lfsa000b21a_e.shp \
        --dbf /path/to/lfsa000b21a_e.dbf \
        --prj /path/to/lfsa000b21a_e.prj \
        --out TorontoLiveEMSKit/Sources/TorontoLiveEMSKit/Resources/TorontoPostalAreas.json \
        --tolerance 10

No libraries: this was written on a machine with no shapefile, projection or geometry package
installed, so the shapefile reader, the Douglas-Peucker simplifier and the inverse Lambert
Conformal Conic are all here.
"""

import argparse
import json
import math
import re
import struct

# --- the shapefile's .prj, parsed rather than remembered ------------------------------------


def projection_from_prj(text):
    """The Lambert Conformal Conic parameters StatCan's boundary files are written in."""

    def parameter(name):
        found = re.search(rf'PARAMETER\["{name}",([-0-9.]+)\]', text)
        if not found:
            raise SystemExit(f"the .prj has no {name}")
        return float(found.group(1))

    sphere = re.search(r'SPHEROID\["GRS_1980",([-0-9.]+),([-0-9.]+)\]', text)
    if not sphere:
        raise SystemExit("the .prj has no GRS_1980 spheroid")

    return {
        "a": float(sphere.group(1)),
        "inv_f": float(sphere.group(2)),
        "phi_1": math.radians(parameter("standard_parallel_1")),
        "phi_2": math.radians(parameter("standard_parallel_2")),
        "phi_0": math.radians(parameter("latitude_of_origin")),
        "lam_0": math.radians(parameter("central_meridian")),
        "false_easting": parameter("false_easting"),
        "false_northing": parameter("false_northing"),
    }


class Unprojector:
    """Projected metres -> (longitude, latitude), by the inverse of the .prj's projection."""

    def __init__(self, spec):
        self.a = spec["a"]
        self.e = math.sqrt(2 * (1 / spec["inv_f"]) - (1 / spec["inv_f"]) ** 2)
        self.lam_0 = spec["lam_0"]
        self.false_easting = spec["false_easting"]
        self.false_northing = spec["false_northing"]
        self.n = (math.log(self._m(spec["phi_1"])) - math.log(self._m(spec["phi_2"]))) / (
            math.log(self._t(spec["phi_1"])) - math.log(self._t(spec["phi_2"]))
        )
        self.f = self._m(spec["phi_1"]) / (self.n * self._t(spec["phi_1"]) ** self.n)
        self.rho_0 = self.a * self.f * self._t(spec["phi_0"]) ** self.n

    def _t(self, phi):
        es = self.e * math.sin(phi)
        return math.tan(math.pi / 4 - phi / 2) / ((1 - es) / (1 + es)) ** (self.e / 2)

    def _m(self, phi):
        return math.cos(phi) / math.sqrt(1 - self.e**2 * math.sin(phi) ** 2)

    def __call__(self, x, y):
        rho = math.copysign(
            math.hypot(x - self.false_easting, self.rho_0 - (y - self.false_northing)), self.n
        )
        theta = math.atan2(x - self.false_easting, self.rho_0 - (y - self.false_northing))
        t = (rho / (self.a * self.f)) ** (1 / self.n)
        phi = math.pi / 2 - 2 * math.atan(t)
        for _ in range(12):
            es = self.e * math.sin(phi)
            phi = math.pi / 2 - 2 * math.atan(t * ((1 - es) / (1 + es)) ** (self.e / 2))
        return math.degrees(theta / self.n + self.lam_0), math.degrees(phi)


# --- reading the source ---------------------------------------------------------------------


def dbf_codes(path, field="CFSAUID"):
    """Every record's FSA code, in record order, from the small .dbf beside the .shp."""
    raw = open(path, "rb").read()
    records, header, length = struct.unpack("<I H H", raw[4:12])
    fields, offset = [], 32
    while raw[offset] != 0x0D:
        fields.append((raw[offset : offset + 11].split(b"\x00")[0].decode(), raw[offset + 16]))
        offset += 32
    start, width = 1, 0  # 1 for the deletion flag that opens every record
    for name, size in fields:
        if name == field:
            width = size
            break
        start += size
    return [
        raw[header + i * length + start : header + i * length + start + width]
        .decode("ascii", "replace")
        .strip()
        for i in range(records)
    ]


def shp_rings(path):
    """Yield each record's rings, streaming, so a 297 MB file is never held at once."""
    handle = open(path, "rb")
    handle.seek(100)
    while True:
        header = handle.read(8)
        if len(header) < 8:
            return
        _, content_words = struct.unpack(">i i", header)
        body = handle.read(content_words * 2)
        (shape,) = struct.unpack("<i", body[0:4])
        if shape == 0:
            yield []
            continue
        part_count, point_count = struct.unpack("<i i", body[36:44])
        parts = struct.unpack(f"<{part_count}i", body[44 : 44 + 4 * part_count])
        base = 44 + 4 * part_count
        flat = struct.unpack(f"<{2 * point_count}d", body[base : base + 16 * point_count])
        yield [
            [
                (flat[2 * j], flat[2 * j + 1])
                for j in range(begin, parts[i + 1] if i + 1 < part_count else point_count)
            ]
            for i, begin in enumerate(parts)
        ]


# --- geometry -------------------------------------------------------------------------------


def signed_area(ring):
    total = 0.0
    for i, (x1, y1) in enumerate(ring):
        x2, y2 = ring[(i + 1) % len(ring)]
        total += x1 * y2 - x2 * y1
    return total / 2


def contains(outer, point):
    """Ray casting: is the point inside this ring? Used to attach a hole to its outer ring."""
    x, y = point
    inside = False
    for i, (x1, y1) in enumerate(outer):
        x2, y2 = outer[(i - 1) % len(outer)]
        if (y1 > y) != (y2 > y):
            if x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                inside = not inside
    return inside


def simplify(points, tolerance):
    """Douglas-Peucker, in the file's own metres, so a tolerance is a distance."""
    if tolerance <= 0 or len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        first, last = stack.pop()
        if last <= first + 1:
            continue
        x1, y1 = points[first]
        x2, y2 = points[last]
        dx, dy = x2 - x1, y2 - y1
        norm = math.hypot(dx, dy)
        worst, worst_at = -1.0, -1
        for i in range(first + 1, last):
            px, py = points[i]
            distance = (
                math.hypot(px - x1, py - y1)
                if norm == 0
                else abs(dy * px - dx * py + x2 * y1 - y2 * x1) / norm
            )
            if distance > worst:
                worst, worst_at = distance, i
        if worst > tolerance:
            keep[worst_at] = True
            stack.append((first, worst_at))
            stack.append((worst_at, last))
    return [point for point, kept in zip(points, keep) if kept]


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--shp", required=True)
    parser.add_argument("--dbf", required=True)
    parser.add_argument("--prj", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument(
        "--tolerance",
        type=float,
        default=10.0,
        help="simplification tolerance in metres; the error this introduces, at most",
    )
    arguments = parser.parse_args()

    unproject = Unprojector(projection_from_prj(open(arguments.prj).read()))
    codes = dbf_codes(arguments.dbf)

    # An FSA is letter, digit, letter. M is Toronto's postal district and only Toronto's.
    toronto = {
        index
        for index, code in enumerate(codes)
        if len(code) == 3 and code[0] == "M" and code[1].isdigit() and code[2].isalpha()
    }
    print(f"  {len(codes)} FSAs nationally, {len(toronto)} of them Toronto's")

    features, outer_rings, holes, shrunk, points_in, points_out = [], 0, 0, 0, 0, 0
    for index, rings in enumerate(shp_rings(arguments.shp)):
        if index not in toronto or not rings:
            continue
        points_in += sum(len(ring) for ring in rings)

        outers = [ring for ring in rings if signed_area(ring) < 0]
        inners = [ring for ring in rings if signed_area(ring) >= 0]
        outer_rings += len(outers)
        holes += len(inners)

        polygons = []
        unclaimed = list(inners)
        for outer in outers:
            simplified = simplify(outer, arguments.tolerance)
            if len(simplified) < 4:
                # A ring that simplification destroys — a small island, usually — is kept
                # unsimplified rather than dropped. Nothing published means nothing drawn, and
                # silently losing fourteen of them is exactly the kind of quiet omission this
                # project has had to unlearn: the count of rings in must match the count out.
                simplified = outer
                shrunk += 1
            ring = simplified + [simplified[0]] if simplified[0] != simplified[-1] else simplified
            rings_out = [[[round(v, 5) for v in unproject(x, y)] for x, y in ring]]
            for hole in list(unclaimed):
                if contains(outer, hole[0]):
                    unclaimed.remove(hole)
                    simplified_hole = simplify(hole, arguments.tolerance)
                    if len(simplified_hole) >= 4:
                        closed = (
                            simplified_hole + [simplified_hole[0]]
                            if simplified_hole[0] != simplified_hole[-1]
                            else simplified_hole
                        )
                        rings_out.append(
                            [[round(v, 5) for v in unproject(x, y)] for x, y in closed]
                        )
            polygons.append(rings_out)
            # Counted here rather than before the rings are built, so the number reported is the
            # number written — the rings kept whole above are part of it.
            points_out += sum(len(ring) for ring in rings_out)

        if polygons:
            features.append(
                {
                    "type": "Feature",
                    "properties": {"fsa": codes[index]},
                    "geometry": (
                        {"type": "Polygon", "coordinates": polygons[0]}
                        if len(polygons) == 1
                        else {"type": "MultiPolygon", "coordinates": polygons}
                    ),
                }
            )
        if unclaimed:
            print(f"  note: {codes[index]} had {len(unclaimed)} ring(s) inside no other ring")

    features.sort(key=lambda feature: feature["properties"]["fsa"])
    document = {
        "type": "FeatureCollection",
        "attribution": (
            "Contains information licensed under the Open Government Licence – Canada. "
            "Forward sortation area boundaries: Statistics Canada, 2021 Census."
        ),
        "source": "Statistics Canada, 2021 Census – Forward sortation area boundary file",
        "licence": "Open Government Licence – Canada",
        "simplifiedToMetres": arguments.tolerance,
        "coordinates": "longitude, latitude (WGS84), as GeoJSON requires",
        "features": features,
    }
    payload = json.dumps(document, separators=(",", ":"))
    open(arguments.out, "w").write(payload)

    print(
        f"  wrote {arguments.out}: {len(features)} areas, {outer_rings} outer rings, "
        f"{holes} holes"
    )
    if shrunk:
        print(f"  {shrunk} ring(s) were too small to simplify and are kept whole")
    print(
        f"  points {points_in} -> {points_out} at {arguments.tolerance:g} m "
        f"({100 * points_out / points_in:.1f}%)"
    )
    print(f"  bytes {len(payload)} ({len(payload) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
