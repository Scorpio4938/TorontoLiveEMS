import Foundation

/// One police division, as the City of Toronto publishes it.
///
/// **A number and its published area.** The boundary file carries 19 features, each with a division
/// number and a MultiPolygon. Both are kept: the number is what a call names, and the area is what a
/// division page and the Divisions map draw. Unlike a station, a division is a coverage area rather
/// than a point, so a pin would say less than the City did.
public struct PoliceDivision: Sendable, Equatable, Identifiable, Decodable {

    public var id: String { number }

    /// The division number as the City publishes it, e.g. `14`.
    ///
    /// This is the stored spelling, and the one lookup keys on. It is not the form a screen shows;
    /// `feedCode` is.
    public let number: String

    /// The feed's spelling, e.g. `D14`, and **the only form a screen shows**.
    ///
    /// The City's file spells the same division `14`; the feed spells it `D14`. The app must not
    /// show both as if they were two things, so a screen renders this form throughout, and the
    /// stored `number` never reaches a label.
    public var feedCode: String { "D" + number }

    /// The published area, as one or more pieces with holes.
    ///
    /// A division is a coverage area. The pieces are kept exactly as the City published them,
    /// rounded only enough to be JSON-sized; a division with no area is not something the app can
    /// draw and is not in the published file.
    public let areas: [Area]

    /// The box that contains every piece, or `nil` when there is no area to measure.
    public var bounds: Bounds? {
        var south = Double.greatestFiniteMagnitude
        var north = -Double.greatestFiniteMagnitude
        var west = Double.greatestFiniteMagnitude
        var east = -Double.greatestFiniteMagnitude
        for area in areas {
            for point in area.outer + area.holes.flatMap({ $0 }) {
                south = Swift.min(south, point.latitude)
                north = Swift.max(north, point.latitude)
                west = Swift.min(west, point.longitude)
                east = Swift.max(east, point.longitude)
            }
        }
        guard south <= north, west <= east else { return nil }
        return Bounds(south: south, north: north, west: west, east: east)
    }

    /// Whether a coordinate falls inside one piece of the division.
    ///
    /// Holes count: a hole is ground that is not part of the division. The ray cast is the same
    /// shape `PostalAreas` uses for its rings.
    public static func contains(_ point: Point, in area: Area) -> Bool {
        guard contains(point, in: area.outer) else { return false }
        return !area.holes.contains { contains(point, in: $0) }
    }

    /// Whether a published division string — `D14` or `14` — names this division.
    ///
    /// This is what a live call's `division` is tested with. The value is the feed's, so it must
    /// accept both spellings without the call site learning the rule.
    public func matches(published: String) -> Bool {
        PoliceDivisions.normalised(published) == number
    }

    /// One coordinate in the published area, in degrees.
    ///
    /// The generated file stores `[latitude, longitude]`; GeoJSON writes the reverse, and the
    /// generator is the one place that swaps them.
    public struct Point: Sendable, Equatable, Decodable {
        public let latitude: Double
        public let longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        public init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let latitude = try container.decode(Double.self)
            let longitude = try container.decode(Double.self)
            self.init(latitude: latitude, longitude: longitude)
        }
    }

    /// One piece of a division: an outer ring and any rings inside it.
    public struct Area: Sendable, Equatable, Decodable {
        public let outer: [Point]
        public let holes: [[Point]]
    }

    /// The box a division occupies, in degrees.
    public struct Bounds: Sendable, Equatable {
        public let south: Double
        public let north: Double
        public let west: Double
        public let east: Double

        public var centre: Point {
            Point(latitude: (south + north) / 2, longitude: (west + east) / 2)
        }

        public var latitudeSpan: Double { north - south }
        public var longitudeSpan: Double { east - west }

        /// Above the middle of the box: where a callout for this division hangs from.
        public var northCentre: Point {
            Point(latitude: north, longitude: centre.longitude)
        }
    }

    private static func contains(_ point: Point, in ring: [Point]) -> Bool {
        guard ring.count >= 3 else { return false }

        var inside = false
        var previous = ring[ring.count - 1]
        for current in ring {
            let straddles =
                (current.latitude > point.latitude) != (previous.latitude > point.latitude)
            if straddles {
                let along =
                    (point.latitude - current.latitude)
                    / (previous.latitude - current.latitude)
                let crossing =
                    current.longitude + along * (previous.longitude - current.longitude)
                if point.longitude < crossing { inside.toggle() }
            }
            previous = current
        }
        return inside
    }
}

/// The police divisions the City publishes boundaries for, and where the file came from.
///
/// **Why this exists.** A police call arrives with a division string — `D14` — and the City also
/// publishes which divisions exist as 19 boundary features. The boundary file spells the same
/// division `14`. One of the two has to be normalised, and this type makes the City's spelling the
/// stored one: the file holds `14`, a lookup accepts `14` or `D14`, and a screen renders `feedCode`
/// so the app can never show both.
///
/// **19 divisions, including `00`.** The published file carries all 19 rows, so the file the app
/// ships does too. Nothing here decides which divisions are interesting: a division the City
/// publishes is a division the app can name.
///
/// **The area is shipped too.** Unlike the station and facility files, this one keeps the published
/// MultiPolygon, so the Divisions map can answer *what ground does D14 cover* rather than only
/// *where is its building*.
///
/// `scripts/make_reference_data.py` writes the file, and re-running that script is the only way it
/// changes.
public struct PoliceDivisions: Sendable {

    /// Where the file came from. Required by the licence, and traceable to a URL rather than to
    /// memory.
    public let source: String

    /// The licence the published source is released under.
    public let licence: String

    /// The date the file was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    private let byNumber: [String: PoliceDivision]

    /// How many divisions the file holds.
    public var count: Int { byNumber.count }

    /// Every division, in number order.
    public var divisions: [PoliceDivision] {
        byNumber.values.sorted { $0.number < $1.number }
    }

    /// The division a published value names, accepting either the City's `14` or the feed's
    /// `D14`.
    ///
    /// Case does not matter, and surrounding whitespace is ignored. A value the file does not hold
    /// returns `nil` rather than a made-up division.
    public func division(forPublished published: String) -> PoliceDivision? {
        byNumber[Self.normalised(published)]
    }

    /// The divisions that shipped with the app — or an empty set.
    ///
    /// Empty rather than fatal when the resource is missing or unreadable, because a screen that
    /// cannot name a division can still show the feed's own string, and a worse answer beats a
    /// crash. The tests assert that the resource does load, so a packaging mistake fails there
    /// rather than shipping quietly.
    public static let bundled: PoliceDivisions = {
        guard
            let url = Bundle.module.url(
                forResource: "TorontoPoliceDivisions",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let divisions = try? PoliceDivisions(data: data)
        else {
            return PoliceDivisions()
        }
        return divisions
    }()

    /// Reads the generated file.
    ///
    /// Throws rather than returning nothing, so a caller can tell a broken file from an empty one.
    /// `bundled` is the caller that decides to carry on regardless.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)

        var byNumber: [String: PoliceDivision] = [:]
        for division in document.divisions {
            // Normalise on the way in as well as on the way out, so a file that spells a division
            // two ways is refused rather than silently holding two rows for one division.
            let number = Self.normalised(division.number)
            guard byNumber[number] == nil else {
                throw PoliceDivisionsError.duplicateDivision(number)
            }
            byNumber[number] = PoliceDivision(number: number, areas: division.areas)
        }

        self.source = document.source
        self.licence = document.licence
        self.retrieved = document.retrieved
        self.byNumber = byNumber
    }

    private init() {
        self.source = ""
        self.licence = ""
        self.retrieved = ""
        self.byNumber = [:]
    }

    static func normalised(_ published: String) -> String {
        let trimmed = published
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return trimmed.hasPrefix("D") ? String(trimmed.dropFirst()) : trimmed
    }
}

/// What can go wrong reading the file.
public enum PoliceDivisionsError: Error, Equatable {
    /// Two rows name the same division, after normalisation.
    case duplicateDivision(String)
}

private extension PoliceDivisions {

    struct Document: Decodable {
        let source: String
        let licence: String
        let retrieved: String
        let divisions: [PoliceDivision]
    }
}
