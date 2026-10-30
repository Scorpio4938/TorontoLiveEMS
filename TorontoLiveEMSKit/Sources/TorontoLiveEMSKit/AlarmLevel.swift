import Foundation

/// What an incident's Alarm Level means.
///
/// The City documents these meanings in a footnote under its own incidents table; the
/// wording here is theirs. Level 0 needs explaining most, because it is the level
/// almost every incident carries and a bare `0` says nothing on its own.
public enum AlarmLevel {

    /// One level the City documents.
    public struct Level: Equatable, Sendable {

        /// The ordinal as published, e.g. `2`.
        public let published: String

        /// The City's own words for it.
        public let meaning: String
    }

    /// The levels the City documents, in the order they are meant to be read.
    ///
    /// A list rather than the dictionary `meaning(for:)` reads from, because 0 through 6 is an
    /// order and a dictionary has none — and this is what a screen renders.
    public static let levels: [Level] = [
        Level(published: "0", meaning: "Initial response (for any event)"),
        Level(published: "1", meaning: "Support fire response"),
        Level(published: "2", meaning: "10–14 emergency vehicles"),
        Level(published: "3", meaning: "15–18 emergency vehicles"),
        Level(published: "4", meaning: "19–22 emergency vehicles"),
        Level(published: "5", meaning: "23–28 emergency vehicles"),
        Level(published: "6", meaning: "29–32 emergency vehicles"),
    ]

    /// Toronto Fire Services' explanation of *how* a level is arrived at, paraphrased.
    ///
    /// The levels above say what a number means; this says why a number changes, which is the
    /// thing a reader who has seen an incident escalate actually wonders. The factors are the
    /// service's own; the sentences are ours, because the original ran to a paragraph of
    /// dispatcher procedure that no reader of a number needs.
    public static let escalationNote = """
        A level can be raised at any time: by a dispatcher reading the 911 calls, by crews who \
        arrive to smoke or are told what is inside, or by the size and duration of the fire, the \
        weather, the people inside, or the extra apparatus needed.
        """

    /// What the vehicle counts above actually count, paraphrased.
    ///
    /// The sentence that stops a reader thinking the app is wrong. They see *Alarm Level 2 =
    /// 10–14 emergency vehicles* beside a roster of five tokens and conclude something has been
    /// miscounted; this is the answer. The rule is the service's and must stay exact; the
    /// sentence wrapping it does not have to be.
    public static let countingNote = """
        Only Pumpers, Aerials, Rescues and Squads are counted. Hazmat, Air Lights, District \
        Chiefs and Command vehicles are not.
        """

    /// The City's meaning for a published level, or `nil` if it publishes a level we
    /// have not seen.
    public static func meaning(for published: String) -> String? {
        return meanings[published.trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    /// Whether the City sent ten or more vehicles: level 2 and above.
    ///
    /// **The threshold is the City's, not ours.** Its own meanings put the line between `1` and
    /// `2`: level `0` is an initial response, level `1` is a *support* fire response — one more
    /// crew — and level `2` is already **10–14 emergency vehicles**. So `2` is where an incident
    /// stops being one the City added a crew to and becomes one it mobilised for, which is why the
    /// app spends its loudest colour there and not at `1`.
    ///
    /// Anything that is not a number is not a major response: the feed is inconsistent with itself
    /// and a value we cannot read is one we must not colour as if we could.
    public static func isMajorResponse(_ published: String) -> Bool {
        let trimmed = published.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let level = Int(trimmed) else { return false }
        return level >= 2
    }

    /// Derived from `levels`, so the two cannot disagree about what a level means.
    private static let meanings: [String: String] = Dictionary(
        uniqueKeysWithValues: levels.map { ($0.published, $0.meaning) }
    )
}
