import Foundation

/// One apparatus code, and what the app can say about it.
///
/// **The name comes from the City's legend, and from its longest matching entry.** `CMD` is a
/// Command Vehicle rather than a Chief, and `PL231` is a Platform rather than a Pumper, because
/// the legend's longest code that prefixes the token is the one that names it. `DispatchedUnit`
/// already owns that rule, so this type asks it rather than keeping a second copy.
///
/// **A station number is not merely digits.** `C23` is a Chief's car and its `23` is not a
/// published station number, so it belongs to no station; `P244` has digits that are Station 244's,
/// so it does. The difference matters because a reader shown "Chief 23" beside a station address
/// would be told something the City never said. `FireStations` is the only authority on which
/// numbers are stations.
public struct FireUnit: Sendable, Equatable, Identifiable, Decodable {

    public var id: String { code }

    /// The token exactly as the feed publishes it, e.g. `P244`.
    public let code: String

    /// The City's name for the apparatus, or `nil` when the legend does not name this code.
    ///
    /// Nil is a real case. The legend is not provably exhaustive — `L` is dispatched but not named
    /// on the City's page — and an unnamed code is shown as its code rather than guessed at.
    public let name: String?

    /// The station the unit belongs to, or `nil` when its digits are not a station number.
    public let station: Int?

    /// A unit derived from one published code and the stations the app knows.
    ///
    /// This is the rule the import applies, exposed so a code the capture did not happen to contain
    /// can still be asked about. The file ships the same answer for every code it holds, and a test
    /// checks the two against each other.
    public init(code: String, stations: FireStations) {
        let decoded = DispatchedUnit(code: code)
        self.code = decoded.code
        self.name = decoded.apparatus

        if let digits = decoded.station,
            let number = Int(digits),
            stations.station(number: number) != nil
        {
            self.station = number
        } else {
            self.station = nil
        }
    }
}

extension FireUnit {

    /// Whether an incident's published roster names this unit.
    ///
    /// **Exact code, not a substring.** The feed publishes a comma-separated roster of codes, and
    /// `P24` must not match an incident carrying `P244`. `DispatchedUnit.roster` already splits and
    /// trims that value, so this asks it rather than splitting the string a second time.
    ///
    /// An incident that published no roster names no unit, which is not an error: the feed omits
    /// `units_disp` for roughly one incident in five.
    public func isDispatched(to incident: Incident) -> Bool {
        DispatchedUnit.roster(from: incident.dispatchedUnits).contains { $0.code == code }
    }
}

/// One letter's worth of the units catalogue.
///
/// **The letter groups rows; it does not name them.** A `C` section holds Chief cars and Command
/// Vehicles together, and each row still says which it is. Grouping by the first letter is a way to
/// find a code quickly, not a reading of the legend.
public struct FireUnitGroup: Sendable, Equatable, Identifiable {

    public var id: String { letter }

    /// The leading letter of every code in this group, e.g. `C`.
    public let letter: String

    /// The units in this group, in code order.
    public let units: [FireUnit]
}

/// The apparatus codes seen in one capture of the live fire feed, and where the file came from.
///
/// **Ours, not the City's.** The City publishes no list of apparatus; it publishes the units it
/// dispatched at the moment someone reads the feed. This file is that moment, baked: the codes that
/// appeared in the captured feed, each named from the City's legend, and placed at a station when
/// its digits are one of the 84 published station numbers. It records the feed's own timestamp for
/// the capture, as well as the date the script read it.
///
/// **One capture, not a census.** A unit that was not dispatched that day is not in the file, and
/// that is not a claim that it does not exist. A screen that needs to name a code the file does not
/// hold can ask `FireUnit(code:stations:)`, which applies the same rules without a capture.
///
/// `scripts/make_reference_data.py` writes the file, and re-running that script is the only way it
/// changes.
public struct FireUnits: Sendable {

    /// Where the file came from. Required by the licence, and traceable to a URL rather than to
    /// memory.
    public let source: String

    /// The licence the published source is released under.
    public let licence: String

    /// The date the file was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    /// The feed's own `update_from_db_time` for the capture, verbatim, e.g.
    /// `2026-10-29 16:40:01`. Toronto wall-clock, as the feed publishes it.
    public let capturedAt: String

    private let byCode: [String: FireUnit]

    /// How many unit codes the capture held.
    public var count: Int { byCode.count }

    /// Every unit, in code order.
    public var units: [FireUnit] { byCode.values.sorted { $0.code < $1.code } }

    /// The unit with this code, or `nil` when the capture did not hold it.
    public func unit(code: String) -> FireUnit? {
        byCode[code.trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    /// The units the catalogue places at one station, in code order.
    ///
    /// **An empty array is a real answer.** A station with no captured unit is not an error, and a
    /// screen showing that station omits the section rather than drawing a blank one. The station
    /// number is the only key: a unit whose digits are not a published station has no station, so it
    /// cannot appear under one.
    public func units(at station: Int) -> [FireUnit] {
        units.filter { $0.station == station }
    }

    /// The catalogue grouped by the leading letter of each code, in letter order.
    ///
    /// The group is found from `code` and nothing else — never from `name`. A `C` section therefore
    /// mixes Chief cars and Command Vehicles, and each row still says what it is.
    public var groups: [FireUnitGroup] {
        Self.groups(of: units)
    }

    /// Groups any list of units by the leading letter of each code, in letter order.
    ///
    /// Exposed rather than kept private so a test can group the letter-collision pair the bundled
    /// capture does not happen to contain (`C23` and `CMD…`) without inventing a second rule.
    public static func groups(of units: [FireUnit]) -> [FireUnitGroup] {
        let byLetter = Dictionary(grouping: units) { unit in
            String(unit.code.prefix(1)).uppercased()
        }

        return byLetter.keys.sorted().compactMap { letter in
            guard let group = byLetter[letter] else { return nil }
            return FireUnitGroup(
                letter: letter,
                units: group.sorted { $0.code < $1.code }
            )
        }
    }

    /// The units that shipped with the app — or an empty set.
    ///
    /// Empty rather than fatal when the resource is missing or unreadable, because a screen that
    /// cannot name a unit can still show its code, and a worse answer beats a crash. The tests
    /// assert that the resource does load, so a packaging mistake fails there rather than shipping
    /// quietly.
    public static let bundled: FireUnits = {
        guard
            let url = Bundle.module.url(forResource: "TorontoFireUnits", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let units = try? FireUnits(data: data)
        else {
            return FireUnits()
        }
        return units
    }()

    /// Reads the generated file.
    ///
    /// Throws rather than returning nothing, so a caller can tell a broken file from an empty one.
    /// `bundled` is the caller that decides to carry on regardless.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)

        var byCode: [String: FireUnit] = [:]
        for unit in document.units {
            guard byCode[unit.code] == nil else {
                throw FireUnitsError.duplicateUnit(unit.code)
            }
            byCode[unit.code] = unit
        }

        self.source = document.source
        self.licence = document.licence
        self.retrieved = document.retrieved
        self.capturedAt = document.capturedAt
        self.byCode = byCode
    }

    private init() {
        self.source = ""
        self.licence = ""
        self.retrieved = ""
        self.capturedAt = ""
        self.byCode = [:]
    }
}

/// What can go wrong reading the file.
public enum FireUnitsError: Error, Equatable {
    /// Two rows carry the same code. A code is what identifies a unit, so a file with two answers
    /// for one code is not a file this app can use.
    case duplicateUnit(String)
}

private extension FireUnits {

    struct Document: Decodable {
        let source: String
        let licence: String
        let retrieved: String
        let capturedAt: String
        let units: [FireUnit]
    }
}
