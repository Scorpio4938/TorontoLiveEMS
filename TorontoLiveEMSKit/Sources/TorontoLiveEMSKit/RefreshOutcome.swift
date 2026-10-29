import Foundation

/// What a refresh did.
///
/// **Top level rather than nested in `IncidentFeed`, which is where it started.** Two feeds answer
/// this question now, and the police feed must not have to name the fire feed's type in order to
/// answer it: fire and police share the presentation layer, not each other's clients. The same
/// argument that put `FeedStatus` in a file of its own.
public enum RefreshOutcome: Equatable, Sendable {

    /// A refresh that was not proved to be a skip: the calls were fetched, or the attempt failed.
    case refreshed

    /// Nothing newer was found — by whatever test that feed is able to make. Fire can decline to ask
    /// at all, because the City's republish tick is inside the document it already fetched. Police asks
    /// the Service for its stamp, fetches only when that stamp is not the one the calls were read under,
    /// and then compares what came back. Both answer this, and the reader sees the same word either way.
    case skipped
}
