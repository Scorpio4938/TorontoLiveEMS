import Foundation

/// One fire station, as the City of Toronto publishes it.
///
/// The live feed names an incident's Area as a bare station number — `231` — and names apparatus by
/// the station it belongs to — `P231`. A number is not a place, so the app needs the City's own row
/// for the station before it can say where that number is. This is that row.
public struct FireStation: Sendable, Equatable, Identifiable, Decodable {

    /// The station number the feed uses, e.g. `231`.
    public var id: Int { number }
    public let number: Int

    /// The street address as published, e.g. `740 Markham Rd`.
    public let address: String

    /// The municipality the station is in, in the City's own wording — `Scarborough`,
    /// `North York`, `Etobicoke`, `York`, `East York`, or `former Toronto`.
    public let municipality: String

    /// The year the station was built, as published.
    public let yearBuilt: Int

    /// The municipal ward the station sits in.
    public let ward: Ward

    /// The offices the station houses, in the order the City publishes them.
    ///
    /// Empty for most stations. The published file has three columns for this — public education,
    /// fire prevention, and other — and their values are names rather than codes, so the file keeps
    /// the names and says nothing about which column each came from. A station with none publishes
    /// a blank or the word `None`, and neither is an office.
    public let offices: [String]

    /// The published point, in degrees (WGS84).
    public let coordinate: Coordinate

    public struct Ward: Sendable, Equatable, Decodable {
        public let number: Int
        public let name: String
    }

    public struct Coordinate: Sendable, Equatable, Decodable {
        public let latitude: Double
        public let longitude: Double
    }
}

/// Every fire station the City publishes, and where the file came from.
///
/// **Why this exists.** The feed publishes a station number and nothing about the station. The
/// City also publishes the station locations as open data, and this is that file reduced to the
/// fields the app can name: number, address, municipality, year built, ward, offices, and a point.
/// `scripts/make_reference_data.py` writes it, and re-running that script is the only way it
/// changes.
///
/// **84 stations, not 85.** The published file also carries an operations training site at
/// 25 Old Eglinton Ave. It is a City facility and not a station, and it has no station number, so
/// the import filters on the published `TYPE_DESC` rather than counting rows. Counting rows would
/// ship the training site and leave the app unable to name it as a station.
///
/// **The coordinates are the City's, not Apple's.** This is the opposite of an incident's location,
/// which the feed publishes as a street and the app has to geocode. A station's point is published
/// outright, and no screen has to ask a second service where a station is.
///
/// **In the package rather than the app**, for the reason `PostalAreas` gives: the app target has no
/// tests, and a reference file is exactly the kind of data that can be plausible and wrong.
public struct FireStations: Sendable {

    /// Where the file came from. Required by the licence, and traceable to a URL rather than to
    /// memory.
    public let source: String

    /// The licence the published source is released under.
    public let licence: String

    /// The date the file was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    private let byNumber: [Int: FireStation]

    /// How many stations the file holds.
    public var count: Int { byNumber.count }

    /// Every station, in station-number order.
    public var stations: [FireStation] { byNumber.values.sorted { $0.number < $1.number } }

    /// Every station number, in order. This is what a unit's digits are checked against.
    public var numbers: [Int] { stations.map(\.number) }

    /// The station with this number, or `nil` when the file has none.
    public func station(number: Int) -> FireStation? {
        byNumber[number]
    }

    /// The stations that shipped with the app — or an empty set.
    ///
    /// Empty rather than fatal when the resource is missing or unreadable, because a screen that
    /// cannot name a station can still show its number, and a worse answer beats a crash. The tests
    /// assert that the resource does load, so a packaging mistake fails there rather than shipping
    /// quietly.
    public static let bundled: FireStations = {
        guard
            let url = Bundle.module.url(forResource: "TorontoFireStations", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let stations = try? FireStations(data: data)
        else {
            return FireStations()
        }
        return stations
    }()

    /// Reads the generated file.
    ///
    /// Throws rather than returning nothing, so a caller can tell a broken file from an empty one.
    /// `bundled` is the caller that decides to carry on regardless.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)

        var byNumber: [Int: FireStation] = [:]
        for station in document.stations {
            guard byNumber[station.number] == nil else {
                throw FireStationsError.duplicateStation(station.number)
            }
            byNumber[station.number] = station
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
}

/// What can go wrong reading the file.
public enum FireStationsError: Error, Equatable {
    /// Two rows claim the same station number. A station number is the key the feed uses, so a
    /// file with two answers for one number is not a file this app can use.
    case duplicateStation(Int)
}

private extension FireStations {

    struct Document: Decodable {
        let source: String
        let licence: String
        let retrieved: String
        let stations: [FireStation]
    }
}
