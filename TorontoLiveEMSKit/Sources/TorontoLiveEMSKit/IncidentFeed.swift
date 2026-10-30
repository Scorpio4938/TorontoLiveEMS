import Foundation
import Observation

/// The active incidents the app is showing, and everything about how they got here.
///
/// **One home for the feed's state.** These were seven properties scattered through a view,
/// which meant the view was the only thing that knew whether a refresh was in flight, whether
/// what is on screen is the last good result, and when a refresh may be skipped. That is logic
/// about the feed, not about the layout, and two screens now need it.
///
/// **In the package rather than the app target, for one reason: tests.** `swift test` reaches
/// this module and cannot reach the app target at all, and the refresh policy below is exactly
/// the kind of thing that should be covered. `FeedRefresh` is already tested; the flow around
/// it was not, and this is what makes it testable.
///
/// `@Observable` and `@MainActor` are the shape `IncidentGeocoder` already uses. Views receive
/// it as an ordinary property — **never through `@Environment`**, where a missing key traps
/// rather than degrading.
///
/// **It reads neither the clock nor the network directly.** Both are injected: the five-minute
/// gate can then be tested at its boundaries without waiting for the City, and no test ever
/// touches an undocumented endpoint.
@MainActor
@Observable
public final class IncidentFeed {

    /// What a tap on refresh did.
    ///
    /// Returned rather than left for the caller to infer from the properties. The two cases
    /// have to look different on screen — a skipped refresh that says nothing is
    /// indistinguishable from a button that does not work — so the caller needs to be told
    /// which happened, not left to reconstruct it from a nil-versus-non-nil comparison.
    /// The most recent snapshot, or nothing if the first fetch has not succeeded.
    public private(set) var snapshot: LiveCADSnapshot?

    /// The incidents on screen, most recently dispatched first, or nothing if the first fetch has not
    /// succeeded.
    ///
    /// **The app's order, not the City's.** `LiveCADParser` keeps the order the document published,
    /// which is a separate and correct thing — on the captured feed that order runs oldest to newest —
    /// but a reader arriving on this page wants the newest incident at the top.
    ///
    /// **Stated here, once.** Every screen reads this property rather than sorting the snapshot itself,
    /// so a second screen over the same feed cannot choose a different end of the list.
    ///
    /// Sorted as the published string rather than as a date: it is zero-padded ISO-8601, so string
    /// order is time order and no timezone has to be chosen. An incident with no dispatch time sorts
    /// last, because an empty string compares below every digit — it cannot claim to be the newest.
    public var incidents: [Incident]? {
        snapshot?.incidents.sorted { $0.dispatchTime > $1.dispatchTime }
    }

    /// Why there is no snapshot, in a sentence fit to show. Only set when there is nothing
    /// to show in its place.
    public private(set) var failureMessage: String?

    /// A fetch is in flight. Said in the status line rather than on the button, so the button
    /// keeps its untouched appearance.
    public private(set) var isRefreshing = false

    /// What is on screen is the last good result, and the newest attempt failed. Distinct from
    /// `failureMessage`: this one means there is still something to read.
    public private(set) var isShowingStaleResult = false

    private let fetch: @Sendable () async throws -> LiveCADSnapshot
    private let now: @Sendable () -> Date

    public init(
        fetch: @escaping @Sendable () async throws -> LiveCADSnapshot = {
            try await LiveCADClient().snapshot()
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetch = fetch
        self.now = now
    }

    /// Fetches, and holds on to whatever comes back.
    ///
    /// A failure with nothing on screen is said in place of the list. A failure *with*
    /// something on screen keeps it and flags it stale, because emptying a screen that a
    /// reader is using is worse than telling them it is old.
    public func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            snapshot = try await fetch()
            failureMessage = nil
            isShowingStaleResult = false
        } catch {
            guard snapshot == nil else {
                isShowingStaleResult = true
                return
            }
            failureMessage = "The live feed could not be loaded.\n\(error.localizedDescription)"
        }
    }

    /// Refreshes, unless the City provably has not republished since the tick we hold.
    ///
    /// The feed is a five-minute snapshot of a source that only changes every five minutes, so
    /// between two of its boundaries there is nothing to fetch. Asking anyway would be a
    /// request whose answer we already know, against a server that never offered the endpoint
    /// in the first place.
    @discardableResult
    public func refresh() async -> RefreshOutcome {
        guard FeedRefresh.mayHaveRefreshed(since: snapshot?.updatedFromDatabaseAt, now: now())
        else {
            return .skipped
        }

        await load()
        return .refreshed
    }

    /// The sentence for a refresh that was skipped.
    public var nothingNewerMessage: String {
        let updated = snapshot?.updatedFromDatabaseAt ?? "an unknown time"
        return "Nothing newer than \(updated)."
    }

    /// The feed's own timestamp, and whether what is on screen is the last good result.
    ///
    /// It is the age of the *data*, not of our request, which is what a reader needs in order
    /// to judge whether what they are looking at is current. The City shows the same value; we
    /// add the space after the colon that their page omits.
    ///
    /// A refresh in flight says so here rather than on the button. The feed only changes every
    /// five minutes, so a refresh that returns exactly what we already had is the normal case
    /// and has to be distinguishable from a tap that did nothing.
    ///
    /// No case for having no snapshot. This used to be drawn outside the list, where it was
    /// visible while the first fetch was in flight and could say "Fetching…". It is a section
    /// header now, and a section header only exists when there is a section — so those states
    /// are said by the `ProgressView` and the `ContentUnavailableView` that stand in the
    /// list's place, which is where a reader looks for them anyway.
    public var status: FeedStatus {
        // "City fire data as of", not "Last updated". The value is the City's own refresh tick,
        // and the subject is named so a reader knows whose data this is.
        // update_from_db_time, which lands on a five-minute boundary — and not the moment we
        // fetched it. "Last updated" left that open to exactly the wrong reading.
        let updated = snapshot?.updatedFromDatabaseAt ?? "unknown"
        let base = "City fire data as of \(updated)"

        if isShowingStaleResult {
            return FeedStatus(text: "\(base) · showing the last result", isStale: true)
        }
        if isRefreshing {
            return FeedStatus(text: "\(base) · checking…", isStale: false)
        }
        return FeedStatus(text: base, isStale: false)
    }
}
