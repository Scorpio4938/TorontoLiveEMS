import Foundation

/// What a refresh did.
///
/// **Top level rather than nested in `IncidentFeed`, which is where it started.** Two feeds answer
/// this question now, and the police feed must not have to name the fire feed's type in order to
/// answer it: fire and police share the presentation layer, not each other's clients. The same
/// argument that put `FeedStatus` in a file of its own.
public enum RefreshOutcome: Equatable, Sendable {

    /// Something was fetched.
    case refreshed

    /// Nothing newer was found — by whatever test that feed is able to make. The fire feed can
    /// decline to ask at all, because the City's republish tick is inside the document it already
    /// fetched; the police feed has no such tick in hand, so it fetches and compares. Both answer
    /// this, and the reader sees the same word for it either way.
    case skipped
}
