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

    /// The City's explanation of *how* a level is arrived at.
    ///
    /// Their words. The levels above say what a number means; this says why a number changes,
    /// which is the thing a reader who has seen an incident escalate actually wonders.
    public static let escalationNote = """
        Toronto Fire Services determines the Alarm Level based upon any one of a number of \
        factors. Initially an incident can be upgraded to a working fire response by a \
        dispatcher, based upon the numerous 911 calls received and the detail provided by the \
        public. Alternatively it may be upgraded once TFS arrives on scene and sees smoke or \
        they receive a report from persons on site. If these conditions were not present \
        initially, an Alarm Level may still be upgraded based upon the size and duration of \
        the fire, rotation of crews due to extreme hot or cold weather conditions, numbers and \
        disabilities of people within the structure, or additional specialized apparatus and \
        crews required.
        """

    /// What the vehicle counts above actually count.
    ///
    /// The sentence that stops a reader thinking the app is wrong. They see *Alarm Level 2 =
    /// 10–14 emergency vehicles* beside a roster of five tokens and conclude something has been
    /// miscounted; the City's own footnote is the answer.
    public static let countingNote = """
        Alarm levels are determined by the number of vehicles consisting of Pumpers, Aerials, \
        Rescues and Squads responding to the event. Support vehicles such as Hazmat, Air \
        Lights, District Chiefs and Command vehicles are not included in that count.
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
