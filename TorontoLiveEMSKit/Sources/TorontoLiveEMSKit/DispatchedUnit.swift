import Foundation

/// One piece of apparatus sent to an incident.
///
/// The City publishes a roster of coded tokens — `P231, P234` — and names the codes in
/// a footnote legend on its own incidents page. The names here are that legend,
/// verbatim; we did not invent them.
public struct DispatchedUnit: Equatable, Sendable {

    /// The token exactly as published, e.g. `LA231`.
    public let code: String

    /// The City's name for the apparatus type, or `nil` when the token's code is not
    /// in the City's legend.
    public let apparatus: String?

    /// The station number carried by the token, e.g. `231`.
    public let station: String?

    /// What to show for this unit.
    ///
    /// A code we cannot decode stays visibly undecoded — the raw token — rather than
    /// being guessed at. The legend is not provably exhaustive, and an unfamiliar
    /// token is more honest than a confidently wrong apparatus name.
    public var display: String {
        guard let apparatus else {
            return code
        }
        guard let station else {
            return apparatus
        }
        return "\(apparatus) \(station)"
    }

    /// Parses one published token, e.g. `LA231`.
    public init(code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = Self.trailingDigits(of: trimmed)

        // Longest code first, so `PL123` reads as Platform rather than Pumper, `CMD1`
        // as Command Vehicle rather than Chief, and `Sup7` as Canteen rather than Squad.
        var apparatusName: String?
        for candidate in Self.legend where trimmed.hasPrefix(candidate.code) {
            apparatusName = candidate.name
            break
        }

        self.code = trimmed
        self.apparatus = apparatusName
        self.station = digits.isEmpty ? nil : digits
    }

    /// The units in a published roster such as `P231, P234`, with a repeated unit shown once.
    ///
    /// **No capture in this repository contains a duplicate roster.** The fixture is clean; the live
    /// feed has been seen naming the same token twice for one incident, so this is defensive against a
    /// defect observed rather than one reproducible from the capture. Identity is the trimmed token
    /// compared case-insensitively, and the first occurrence keeps its position.
    ///
    /// The published string is left untouched on `Incident.dispatchedUnits`: this is a reading of it,
    /// not a correction to what the City sent.
    public static func roster(from published: String?) -> [DispatchedUnit] {
        uniqueTokens(from: published).map { DispatchedUnit(code: String($0)) }
    }

    /// The published roster as the compact table shows it, with a repeated unit shown once.
    ///
    /// The same identity rule as `roster(from:)`, applied to the table's raw-token form rather than to
    /// decoded units. The kept token is the text the City sent, so its case and spacing are not
    /// normalised, and the published order is preserved. `nil` when there is nothing to show.
    public static func displayRoster(from published: String?) -> String? {
        let tokens = uniqueTokens(from: published)
        return tokens.isEmpty ? nil : tokens.joined(separator: ",")
    }

    /// The published tokens, one per unit, in published order, with a repeated unit removed.
    ///
    /// The one place the comparison is decided, so the table and the detail view cannot disagree about
    /// whether two tokens are the same unit. The first occurrence is the one kept, which is why this
    /// builds a list rather than a set.
    private static func uniqueTokens(from published: String?) -> [Substring] {
        guard let published else {
            return []
        }

        var seen: Set<String> = []
        var kept: [Substring] = []
        for token in published.split(separator: ",") {
            let identity = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !identity.isEmpty, seen.insert(identity).inserted else { continue }
            kept.append(token)
        }
        return kept
    }

    private static func trailingDigits(of token: String) -> String {
        var start = token.endIndex
        while start > token.startIndex {
            let previous = token.index(before: start)
            guard token[previous].isWholeNumber else {
                break
            }
            start = previous
        }
        return String(token[start...])
    }

    /// One entry from the City's legend.
    public struct Legend: Equatable, Sendable {

        /// The code as published at the start of a token, e.g. `HZ`.
        public let code: String

        /// The City's name for that apparatus.
        public let name: String
    }

    /// The City's legend in the order a reader looks something up.
    ///
    /// Sorted by name, where the list it comes from is ordered longest-code-first for prefix
    /// matching. One list, two readings: a parser needs the codes in one order and a person
    /// needs them in another, and neither should be a copy of the other.
    public static var documentedApparatus: [Legend] {
        legend.sorted { $0.name < $1.name }
    }

    /// The City's legend, ordered longest code first so prefix matching is correct.
    static let legend: [Legend] = [
        Legend(code: "Box12", name: "Canteen vehicle"),
        Legend(code: "Sup7", name: "Canteen vehicle"),
        Legend(code: "CMD", name: "Command Vehicle"),
        Legend(code: "TRS", name: "Trench Rescue Support"),
        Legend(code: "PL", name: "Platform"),
        Legend(code: "HR", name: "Highrise"),
        Legend(code: "HZ", name: "HazMat"),
        Legend(code: "FB", name: "Fireboat"),
        Legend(code: "LA", name: "Air Light"),
        Legend(code: "WT", name: "Water Tanker"),
        Legend(code: "HS", name: "Haz Support"),
        Legend(code: "DE", name: "Decon"),
        Legend(code: "MP", name: "Mini Pumper"),
        Legend(code: "FI", name: "Fire Investigator"),
        Legend(code: "P", name: "Pumper"),
        Legend(code: "R", name: "Rescue"),
        Legend(code: "A", name: "Aerial"),
        Legend(code: "T", name: "Tower"),
        Legend(code: "S", name: "Squad"),
        Legend(code: "C", name: "Chief"),
    ]
}
