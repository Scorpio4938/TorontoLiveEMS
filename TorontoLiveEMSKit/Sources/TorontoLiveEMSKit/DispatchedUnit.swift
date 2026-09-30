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

    /// The units in a published roster such as `P231, P234`.
    ///
    /// Returns an empty array when the feed published nothing — which it does for
    /// roughly one incident in five, by omitting the element entirely.
    public static func roster(from published: String?) -> [DispatchedUnit] {
        guard let published else {
            return []
        }
        return published
            .split(separator: ",")
            .map { DispatchedUnit(code: String($0)) }
            .filter { !$0.code.isEmpty }
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

    private struct Legend: Sendable {
        let code: String
        let name: String
    }

    /// The City's legend, ordered longest code first so prefix matching is correct.
    private static let legend: [Legend] = [
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
