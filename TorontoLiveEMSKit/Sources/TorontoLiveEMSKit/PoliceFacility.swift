import Foundation

/// One police facility, when the City publishes it as a division's own address.
///
/// A division's page carries the facility address and postal code the City publishes for it. The
/// published facility file also holds headquarters, collision reporting centres, the college, and
/// marine and mounted units; those are not divisions and are not in this file. A division with no
/// facility row is a real case — the boundary file has 19 divisions and only 16 have one — and the
/// page shows no address rather than a blank labelled row.
public struct PoliceFacility: Sendable, Equatable, Identifiable, Decodable {

    public var id: String { division }

    /// The division number the facility belongs to, as the City's file spells it: `14`.
    public let division: String

    /// The street address, as published.
    public let address: String

    /// The postal code, as published.
    public let postalCode: String

    /// The published point, in degrees (WGS84).
    public let coordinate: Coordinate

    public struct Coordinate: Sendable, Equatable, Decodable {
        public let latitude: Double
        public let longitude: Double
    }
}

/// The police facility rows that belong to a division, and where the file came from.
///
/// `scripts/make_reference_data.py` writes the file from the City's *Police Facility Locations*
/// dataset. It keeps only the facilities whose published name is `<two digits> Division`; a
/// substation is a different building, and a division with no row is absent on purpose.
public struct PoliceFacilities: Sendable {

    /// Where the file came from. Required by the licence, and traceable to a URL rather than to
    /// memory.
    public let source: String

    /// The licence the published source is released under.
    public let licence: String

    /// The date the file was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    private let byDivision: [String: PoliceFacility]

    /// How many divisions have a published facility.
    public var count: Int { byDivision.count }

    /// Every facility, in division order.
    public var facilities: [PoliceFacility] {
        byDivision.values.sorted { $0.division < $1.division }
    }

    /// The facility a division's published number names, accepting either `14` or `D14`.
    ///
    /// Nil is the absent-facility case: the division exists but the City publishes no address for
    /// it, so the page has no row to draw.
    public func facility(forPublished division: String) -> PoliceFacility? {
        byDivision[PoliceDivisions.normalised(division)]
    }

    /// The facilities that shipped with the app — or an empty set.
    ///
    /// Empty rather than fatal when the resource is missing or unreadable, because a division page
    /// can still show its number and live calls, and a worse answer beats a crash. The tests assert
    /// that the resource does load, so a packaging mistake fails there rather than shipping quietly.
    public static let bundled: PoliceFacilities = {
        guard
            let url = Bundle.module.url(
                forResource: "TorontoPoliceFacilities",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let facilities = try? PoliceFacilities(data: data)
        else {
            return PoliceFacilities()
        }
        return facilities
    }()

    /// Reads the generated file.
    ///
    /// Throws rather than returning nothing, so a caller can tell a broken file from an empty one.
    /// `bundled` is the caller that decides to carry on regardless.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)

        var byDivision: [String: PoliceFacility] = [:]
        for facility in document.facilities {
            let division = PoliceDivisions.normalised(facility.division)
            guard byDivision[division] == nil else {
                throw PoliceFacilitiesError.duplicateDivision(division)
            }
            byDivision[division] = facility
        }

        self.source = document.source
        self.licence = document.licence
        self.retrieved = document.retrieved
        self.byDivision = byDivision
    }

    private init() {
        self.source = ""
        self.licence = ""
        self.retrieved = ""
        self.byDivision = [:]
    }
}

/// What can go wrong reading the file.
public enum PoliceFacilitiesError: Error, Equatable {
    /// Two rows claim the same division. A division page needs one address, not two.
    case duplicateDivision(String)
}

private extension PoliceFacilities {

    struct Document: Decodable {
        let source: String
        let licence: String
        let retrieved: String
        let facilities: [PoliceFacility]
    }
}
