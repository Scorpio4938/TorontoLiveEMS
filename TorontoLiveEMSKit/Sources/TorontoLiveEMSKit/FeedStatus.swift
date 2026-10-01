import Foundation

/// What the feed's status line says, and whether it is warning.
///
/// Two values that always travel together, which is why they are one type rather than two
/// parameters on every list arrangement.
///
/// **In the package because `IncidentFeed` composes it.** Deciding which of "City data as of …",
/// "· checking…" and "· showing the last result" wins is a rule about the feed's state, not
/// about the line's layout — and it is a rule two screens now need. `FeedStatusLine`, which
/// draws it, stays in the app target with the rest of the views.
public struct FeedStatus: Equatable, Sendable {

    public let text: String
    public let isStale: Bool

    public init(text: String, isStale: Bool) {
        self.text = text
        self.isStale = isStale
    }
}
