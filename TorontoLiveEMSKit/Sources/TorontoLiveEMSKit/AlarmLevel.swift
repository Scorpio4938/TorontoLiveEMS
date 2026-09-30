import Foundation

/// What an incident's Alarm Level means.
///
/// The City documents these meanings in a footnote under its own incidents table; the
/// wording here is theirs. Level 0 needs explaining most, because it is the level
/// almost every incident carries and a bare `0` says nothing on its own.
public enum AlarmLevel {

    /// The City's meaning for a published level, or `nil` if it publishes a level we
    /// have not seen.
    public static func meaning(for published: String) -> String? {
        return meanings[published.trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    /// Whether the City escalated this incident past an initial response.
    ///
    /// Level `0` is an initial response and covers 99.76% of incidents, so it is the
    /// neutral case and should not be marked. Anything else means a dispatcher or a crew
    /// on scene decided this needed more, which is worth seeing without having to read
    /// the number.
    public static func isEscalated(_ published: String) -> Bool {
        let trimmed = published.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "0"
    }

    private static let meanings: [String: String] = [
        "0": "Initial response",
        "1": "Support fire response",
        "2": "10–14 emergency vehicles",
        "3": "15–18 emergency vehicles",
        "4": "19–22 emergency vehicles",
        "5": "23–28 emergency vehicles",
        "6": "29–32 emergency vehicles",
    ]
}
