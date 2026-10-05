import Foundation
import Observation

/// The police calls the app is showing, and everything about how they got here.
///
/// **The fire feed's shape, with its gate in the same place.** `IncidentFeed` can decline to ask for
/// its incidents at all, because the City's republish tick arrives *inside* the document it already
/// fetched — between two of its five-minute boundaries there is provably nothing to ask for. This
/// Service states a time too, the layer's `editingInfo.dataLastEditDate`, and it moves with the data;
/// but it arrives in the layer's metadata rather than in a query response, so reading it is a request
/// of its own — 10.5 KB, against 22.7 KB for the calls themselves.
///
/// **That request is worth making, because it answers two questions at once.** It is the gate ("the
/// Service last wrote at 17:31 and writes about every twenty minutes, so at 17:41 there is nothing to
/// fetch") and it is the time the status line quotes. One request buys both, which is why this feed
/// gates before the fetch the way fire does rather than only comparing afterwards.
///
/// **And the gate is checked again after a fetch.** Twenty minutes is the Service's pace, not a
/// promise: if a write is late, the gate opens and the calls come back unchanged — still nothing
/// newer, and reported as such rather than as a refresh that found something.
///
/// `@Observable` and `@MainActor`, the same shape as `IncidentFeed`, passed as an ordinary property
/// and **never through `@Environment`**, where a missing key traps rather than degrading.
///
/// **It reads neither the clock nor the network directly.** All three are injected — the two requests
/// separately, so a test can answer one without the other — and the status sentence can be checked at
/// its boundaries without waiting for anybody's server.
@MainActor
@Observable
public final class PoliceCallFeed {

    /// The most recent calls, or nothing if the first fetch has not succeeded.
    public private(set) var calls: [PoliceCall]?

    /// When the Service last wrote to the layer, as the Service states it.
    ///
    /// The publisher's clock rather than ours: it is what the status line quotes and what the gate
    /// reads. `nil` until a metadata response has been read, and `nil` again if the Service stops
    /// stating one — which costs the gate and the line, and nothing else.
    public private(set) var publishedAt: Date?

    /// When the calls were last read successfully.
    ///
    /// **No longer on screen.** The line quotes the Service's time, as the fire line does; a reader
    /// comparing the two screens should not have to learn two sentences. Kept because it is what this
    /// feed knows about itself — the moment its data was last known good.
    public private(set) var lastReadAt: Date?

    /// Why there are no calls, in a sentence fit to show. Only set when there is nothing to show in
    /// its place.
    public private(set) var failureMessage: String?

    /// A read is in flight. Said in the status line rather than on the button, so the button keeps its
    /// untouched appearance.
    public private(set) var isRefreshing = false

    /// What is on screen is the last good result and the newest attempt failed. Distinct from
    /// `failureMessage`: this one means there is still something to read.
    public private(set) var isShowingStaleResult = false

    private let fetch: @Sendable () async throws -> [PoliceCall]
    private let fetchPublishedAt: @Sendable () async throws -> Date?
    private let now: @Sendable () -> Date

    public init(
        fetch: @escaping @Sendable () async throws -> [PoliceCall] = {
            try await CallsForServiceClient().calls()
        },
        fetchPublishedAt: @escaping @Sendable () async throws -> Date? = {
            try await CallsForServiceClient().publishedAt()
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetch = fetch
        self.fetchPublishedAt = fetchPublishedAt
        self.now = now
    }

    /// Reads the Service's clock and then the calls, holding on to whatever comes back.
    ///
    /// **Unconditional, the same as the fire feed's `load()`.** The gate belongs to `refresh()`,
    /// because arriving at the page should show the newest the Service has, whatever the interval
    /// says — the reader has asked to see this feed, not to be told it is too soon.
    ///
    /// A failure with nothing on screen is said in place of the list. A failure *with* something on
    /// screen keeps it and flags it stale, because emptying a screen a reader is using is worse than
    /// telling them it is old.
    public func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await readPublishedAt()
        await readCalls()
    }

    /// Refreshes, and says so when the Service provably cannot have published anything newer.
    ///
    /// Two tests, in this order, and both are needed:
    ///
    /// 1. **Before the fetch** — the Service's own time, plus its twenty-minute pace. Between two of
    ///    its writes there is nothing to fetch, and asking anyway is a request whose answer we already
    ///    know. This is the fire feed's rule with a publisher that states a time instead of a
    ///    wall-clock string.
    /// 2. **After it** — the calls that came back, compared with the calls that were there. A pace is
    ///    not a promise, so a late write leaves the gate open and returns the same list; that is still
    ///    nothing newer, and this is what notices.
    ///
    /// A read that **failed** is never "nothing newer". `readCalls()` keeps the last good calls when
    /// an attempt fails, so an unchanged array is only evidence when the read actually happened —
    /// otherwise a dropped connection would be reported to the reader as reassurance.
    public func refresh() async -> RefreshOutcome {
        isRefreshing = true
        defer { isRefreshing = false }

        await readPublishedAt()

        guard FeedRefresh.mayHaveRefreshed(
            since: publishedAt,
            interval: CallsForServiceFeed.interval,
            now: now()
        ) else {
            return .skipped
        }

        let before = calls
        await readCalls()

        guard failureMessage == nil,
              !isShowingStaleResult,
              let after = calls,
              after != before
        else {
            return .refreshed
        }
        return .skipped
    }

    /// The Service's own time, if the layer will state it.
    ///
    /// A stamp that cannot be read is not something the reader needs to be told: it means the gate
    /// cannot be used, so the next refresh simply fetches. A response with no stamp in it clears this
    /// rather than keeping a time the Service is no longer stating.
    private func readPublishedAt() async {
        do {
            publishedAt = try await fetchPublishedAt()
        } catch {
            // Deliberately silent. The reader's business is the calls, and the calls are still coming.
        }
    }

    /// The calls themselves.
    private func readCalls() async {
        do {
            calls = try await fetch()
            lastReadAt = now()
            failureMessage = nil
            isShowingStaleResult = false
        } catch {
            guard calls == nil else {
                isShowingStaleResult = true
                return
            }
            failureMessage = "The police calls could not be loaded.\n\(error.localizedDescription)"
        }
    }

    /// The sentence for a refresh that was skipped.
    ///
    /// Fire's version names the City's tick, because fire has a tick. This one names the Service's own
    /// last-edit time — the same value and the same shape the status line leads with, so the alert and
    /// the line cannot say different things.
    public var nothingNewerMessage: String {
        guard let publishedAt else {
            return "Nothing newer than the calls already on screen."
        }
        return "Nothing newer than \(DispatchTimestamp.publishedStamp(publishedAt))."
    }

    /// The line above the calls: when the Service last published, and what is happening to them.
    ///
    /// **"TPS data as of", in the fire line's shape and on the fire line's clock.** The time is the
    /// Service's own — the layer's last-edit time, which is what it states about its own data — and it
    /// is written the way the City writes its own: `2026-10-05 12:54:19`, on Toronto's clock, not the
    /// reader's and not in the reader's 12- or 24-hour setting. A reader comparing this screen with the
    /// fire one should not have to work out that two lines in the same place are in two shapes.
    ///
    /// The setting still governs the *calls*: a table cell shows a time of day, where a clock and a
    /// preference are what a reader wants, and a line stating the age of the data wants a date.
    ///
    /// No case for having read nothing yet: the screens say that with a spinner and a sentence in the
    /// list's place, which is where a reader looks for it — the same judgement `IncidentFeed` makes.
    public var status: FeedStatus {
        // A closure rather than the bare function name: `publishedStamp` also takes a calendar, and a
        // default argument applies at a *call site*, not to the function's type — so as a reference it
        // is `(Date, Calendar) -> String` and `map` cannot take it.
        let published = publishedAt.map { DispatchTimestamp.publishedStamp($0) } ?? "an unknown time"
        let base = "TPS data as of \(published)"

        if isShowingStaleResult {
            return FeedStatus(text: "\(base) · showing the last result", isStale: true)
        }
        if isRefreshing {
            return FeedStatus(text: "\(base) · checking…", isStale: false)
        }
        return FeedStatus(text: base, isStale: false)
    }
}
