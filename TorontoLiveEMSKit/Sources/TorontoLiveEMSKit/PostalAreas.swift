import Foundation

/// Toronto's forward sortation areas, as areas rather than as points.
///
/// **Why this exists.** A medical incident's location is published as an FSA — `M6K`, not an
/// address — so the map has to draw an area, and ADR-0004 forbids narrowing it to a point. The
/// honest area is the one Statistics Canada publishes. The circle this replaced was an
/// approximation drawn around wherever a geocoder happened to land: it could spill into a
/// neighbouring FSA, or out into the lake, and the map then claimed ground the City never named.
///
/// **The shapes are bundled because nothing can fetch them.** MapKit has no postal boundary of any
/// kind — there is no such API — and the City's feed carries the code and nothing else.
/// `scripts/make_postal_areas.py` generates the file from the 2021 Census forward sortation area
/// boundary file (Statistics Canada, Open Government Licence – Canada): clipped to Toronto's own
/// FSAs, unprojected from Statistics Canada Lambert into degrees, and simplified. The attribution
/// is required by that licence and travels in the file, so it travels into the app.
///
/// **In the package rather than the app**, so `swift test` can check that the resource loads, that
/// the coordinates land inside Toronto, and that the areas are the size areas are. None of that is
/// checkable from the app target.
///
/// Reading it also settles a question the app used to ask Apple: an FSA no longer needs geocoding.
/// One network round trip per incident disappears, and with it the chance of Apple's answer and
/// the drawn area disagreeing.
public struct PostalAreas: Sendable {

    /// One corner of a ring, in degrees.
    public struct Point: Sendable, Equatable {
        public let latitude: Double
        public let longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }

    /// One piece of an FSA: an outer ring, and any rings inside it.
    ///
    /// A hole is rare — exactly one Toronto FSA has one — and it is kept rather than filled,
    /// because a filled hole would claim ground that is not part of the FSA.
    ///
    /// A ring does not repeat its first point. GeoJSON closes a ring that way; drawing does not
    /// need it, so it is dropped on the way in rather than carried into every map layer.
    public struct Area: Sendable, Equatable {
        public let outer: [Point]
        public let holes: [[Point]]

        public init(outer: [Point], holes: [[Point]] = []) {
            self.outer = outer
            self.holes = holes
        }
    }

    /// The box a postal area occupies, in degrees.
    ///
    /// The app uses it twice for two different reasons: to frame an area on the detail map, and to
    /// hang a callout above one on the general map. Both are presentation, but both are arithmetic
    /// over these coordinates — and the app target has no tests at all while this one does, which
    /// is why the arithmetic lives here.
    public struct Bounds: Sendable, Equatable {
        public let south: Double
        public let north: Double
        public let west: Double
        public let east: Double

        public init(south: Double, north: Double, west: Double, east: Double) {
            self.south = south
            self.north = north
            self.west = west
            self.east = east
        }

        /// The middle of the box.
        public var centre: Point {
            Point(latitude: (south + north) / 2, longitude: (west + east) / 2)
        }

        public var latitudeSpan: Double { north - south }
        public var longitudeSpan: Double { east - west }

        /// Above the middle of the box: where a callout for this area hangs from.
        ///
        /// Not the centre. A card anchored to the middle of an area would be a card covering the
        /// middle of it, and the middle is the one place a postal area's location must never be
        /// read as — see `docs/adr/0004-medical-locations-not-narrowed.md`.
        public var northCentre: Point {
            Point(latitude: north, longitude: centre.longitude)
        }
    }

    /// Required by the licence that governs the shapes. Empty only if the file failed to load.
    public let attribution: String

    /// The tolerance the rings were simplified to, in metres.
    ///
    /// A vertex is a point on the published boundary; the straight line between two of them may
    /// bow this far from it. Ten metres is under two pixels at the closest zoom this app offers.
    public let simplificationMetres: Double

    private let byCode: [String: [Area]]

    /// How many FSAs the file holds.
    public var count: Int { byCode.count }

    /// Every FSA in the file, in order. For diagnostics and for tests that sweep the whole city.
    public var codes: [String] { byCode.keys.sorted() }

    /// The shapes that shipped with the app — or an empty set.
    ///
    /// Empty rather than fatal when the resource is missing or unreadable, because the map can
    /// fall back to the circle it drew before, and a worse answer beats a crash. The tests assert
    /// that the resource does load, so a packaging mistake fails there rather than shipping
    /// quietly.
    public static let bundled: PostalAreas = {
        guard
            let url = Bundle.module.url(forResource: "TorontoPostalAreas", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let areas = try? PostalAreas(data: data)
        else {
            return PostalAreas(byCode: [:], attribution: "", simplificationMetres: 0)
        }
        return areas
    }()

    /// The pieces of one FSA, or nil when the file has none.
    ///
    /// Nil is a real case and not an error: the boundaries are from the 2021 census, and an FSA
    /// created since then would not be in the file. The map's fallback is the circle it used
    /// before.
    ///
    /// Case does not matter. The feed publishes `M6K`; a lower-case code would only ever come from
    /// a test.
    public func areas(for fsa: String) -> [Area]? {
        byCode[fsa.uppercased()]
    }

    /// The box that contains every piece of one FSA, or nil when the file has no such FSA.
    ///
    /// Twelve of Toronto's 96 are in more than one piece, so this is the box of all of them: the
    /// frame the detail map opens on, and the place a callout hangs from.
    public func bounds(for fsa: String) -> Bounds? {
        guard let pieces = areas(for: fsa), !pieces.isEmpty else { return nil }

        var south = Double.greatestFiniteMagnitude
        var north = -Double.greatestFiniteMagnitude
        var west = Double.greatestFiniteMagnitude
        var east = -Double.greatestFiniteMagnitude
        for piece in pieces {
            for point in piece.outer {
                south = Swift.min(south, point.latitude)
                north = Swift.max(north, point.latitude)
                west = Swift.min(west, point.longitude)
                east = Swift.max(east, point.longitude)
            }
        }
        guard south <= north, west <= east else { return nil }
        return Bounds(south: south, north: north, west: west, east: east)
    }

    /// Reads the generated file.
    ///
    /// Throws rather than returning nothing, so a caller can tell a broken file from an empty one.
    /// `bundled` is the caller that decides to carry on regardless.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)
        var byCode: [String: [Area]] = [:]
        for feature in document.features {
            let code = feature.properties.fsa.uppercased()
            byCode[code, default: []].append(contentsOf: try feature.geometry.areas(fsa: code))
        }
        self.byCode = byCode
        self.attribution = document.attribution
        self.simplificationMetres = document.simplifiedToMetres
    }

    private init(byCode: [String: [Area]], attribution: String, simplificationMetres: Double) {
        self.byCode = byCode
        self.attribution = attribution
        self.simplificationMetres = simplificationMetres
    }
}

/// What can go wrong reading the file.
///
/// Both cases mean the file was not the file this code generates, which is worth failing a test
/// over rather than papering across — a silently half-read boundary file would draw a map that
/// looked plausible and was wrong.
public enum PostalAreasError: Error, Equatable {
    /// A geometry kind GeoJSON allows and this file does not use.
    case unsupportedGeometry(String)
    /// A ring with too few corners, or with a coordinate that is not a coordinate.
    case malformedRing(fsa: String)
}

private extension PostalAreas {

    struct Document: Decodable {
        let attribution: String
        let simplifiedToMetres: Double
        let features: [Feature]
    }

    struct Feature: Decodable {
        let properties: Properties
        let geometry: Geometry

        struct Properties: Decodable {
            let fsa: String
        }
    }

    /// GeoJSON geometry, in the two kinds this file uses.
    ///
    /// Two cases rather than one decoded shape, because they differ in nesting depth by a whole
    /// level, and flattening one into the other costs more than it saves.
    enum Geometry: Decodable {
        case polygon([[[Double]]])
        case multiPolygon([[[[Double]]]])

        private enum Key: String, CodingKey {
            case type
            case coordinates
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "Polygon":
                self = .polygon(try container.decode([[[Double]]].self, forKey: .coordinates))
            case "MultiPolygon":
                self = .multiPolygon(try container.decode([[[[Double]]]].self, forKey: .coordinates))
            default:
                throw PostalAreasError.unsupportedGeometry(type)
            }
        }

        /// One FSA is one feature but can be several pieces — 12 of Toronto's 96 are, islands and
        /// split neighbourhoods among them.
        func areas(fsa: String) throws -> [PostalAreas.Area] {
            let polygons: [[[[Double]]]]
            switch self {
            case .polygon(let rings): polygons = [rings]
            case .multiPolygon(let collected): polygons = collected
            }

            return try polygons.compactMap { rings in
                guard let outer = rings.first else { return nil }
                return PostalAreas.Area(
                    outer: try ring(outer, fsa: fsa),
                    holes: try rings.dropFirst().map { try ring($0, fsa: fsa) }
                )
            }
        }

        /// GeoJSON writes a coordinate as `[longitude, latitude]` and closes a ring by repeating
        /// its first point. This is the one place in the app that deals with either fact.
        private func ring(_ values: [[Double]], fsa: String) throws -> [PostalAreas.Point] {
            var points = try values.map { pair -> PostalAreas.Point in
                guard
                    pair.count == 2,
                    (-180...180).contains(pair[0]),
                    (-90...90).contains(pair[1])
                else {
                    throw PostalAreasError.malformedRing(fsa: fsa)
                }
                return PostalAreas.Point(latitude: pair[1], longitude: pair[0])
            }
            if points.count > 1, points.first == points.last {
                points.removeLast()
            }
            guard points.count >= 3 else {
                throw PostalAreasError.malformedRing(fsa: fsa)
            }
            return points
        }
    }
}
