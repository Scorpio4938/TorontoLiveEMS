import Foundation
import Observation

/// The police calls the app is showing, and everything about how they got here.
///
/// **No pace, and no skip that does not ask.** The Service states when it last wrote to the layer,
/// `editingInfo.dataLastEditDate`, and that stamp arrives in a metadata request of its own — 10.5 KB,
/// against 22.7 KB for the calls. The app reads it on every refresh and skips the calls only when it
/// is the stamp the calls on screen were read under. A stamp that has moved is a write the screen has
/// not fetched, and it is fetched. Nothing is skipped without asking.
///
/// **The stamp the line quotes is an as-of, not the Service's newest.** The two differ the moment a
/// write lands between two reads: the Service's newest stamp then describes calls this screen does not
/// have. `asOf` is the publisher's time belonging to the calls on screen; fire gets its as-of for free
/// because the City's tick rides inside the document, and calls have to carry it explicitly.
///
/// **The post-fetch comparison stays.** A stamp can move while the calls do not — the Service edits the
/// layer to remove an expired call and the query returns the same list — so after a fetch the calls are
/// compared with the calls that were there. A skip says nothing newer only when the read succeeded and
/// returned what is already on screen.
///
/// `@Observable` and `@MainActor`, the same shape as `IncidentFeed`, passed as an ordinary property
/// and **never through `@Environment`**, where a missing key traps rather than degrading.
///
/// **It reads neither the clock nor the network directly.** Both requests are injected separately, so a
/// test can answer one without the other, and the status sentence can be checked without waiting for
/// anybody's server. The clock is injected for `lastReadAt`, and decides nothing else.
@MainActor
@Observable
public final class PoliceCallFeed {

    /// The calls as the Service returned them, in its own order.
    ///
    /// **Keep private, because it is not the order anybody reads.** What the Service sends is what the
    /// parser kept, and that order is no longer relied on; `calls` applies the app's rule to it. The
    /// comparison after a fetch reads these lists too, because its question is whether the response
    /// changed rather than how the reader sees it.
    private var receivedCalls: [PoliceCall]?

    /// The calls on screen, most recent first, or nothing if the first fetch has not succeeded.
    ///
    /// **The app's order, not the Service's.** The query asks for an order and the Service happens to
    /// answer newest first, but neither is something this app controls or can state — so the order a
    /// reader sees is applied here, from the instant each call carries.
    ///
    /// **Stated here, once.** The page and the map read this property rather than sorting a copy at
    /// each render site, so two screens over one feed cannot disagree about which end is recent.
    public var calls: [PoliceCall]? {
        receivedCalls?.sorted { $0.occurrenceTime > $1.occurrenceTime }
    }

    /// The Service's stamp for the calls on screen: the last time it wrote to the layer when those
    /// calls were read.
    ///
    /// **As-of, not the Service's latest.** It is what the status line and the skipped-refresh sentence
    /// quote — the age of the data the reader has, not of the data the Service has. `nil` until calls
    /// have been read under a stated stamp, and `nil` again if a successful read finds the Service
    /// stating none.
    public private(set) var asOf: Date?

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
    private let fetchStamp: @Sendable () async throws -> Date?
    private let now: @Sendable () -> Date

    public init(
        fetch: @escaping @Sendable () async throws -> [PoliceCall] = {
            try await CallsForServiceClient().calls()
        },
        fetchStamp: @escaping @Sendable () async throws -> Date? = {
            try await CallsForServiceClient().latestStamp()
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetch = fetch
        self.fetchStamp = fetchStamp
        self.now = now
    }

    /// Reads the Service's stamp and then the calls, holding on to whatever comes back.
    ///
    /// **Unconditional.** Arriving at the page should show the newest the Service has; the comparison
    /// belongs to `refresh()`, because the reader has asked to see this feed, not to be told it is
    /// unchanged.
    ///
    /// The stamp is read first so the calls are recorded under the write they came from. If the Service
    /// writes between the two requests the calls may be newer than their stamp; the next refresh reads
    /// the newer stamp, sees a difference, and fetches again — never the other way round.
    ///
    /// A failure with nothing on screen is said in place of the list. A failure *with* something on
    /// screen keeps it and flags it stale, because emptying a screen a reader is using is worse than
    /// telling them it is old.
    public func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let stamp = await readStamp()
        await readCalls(under: stamp)
    }

    /// Refreshes, skipping the calls only when the Service's stamp is the one on screen.
    ///
    /// **Always asks.** The stamp request is made on every refresh. There is no path that decides from
    /// a clock the app already holds that nothing can have changed: a pace describes the publisher, and
    /// the copy on screen can be a write behind it.
    ///
    /// **Skips only on proof.** An unchanged stamp means the Service has not written since the calls
    /// were read, so there is nothing to fetch. A changed stamp — or one that could not be read, or was
    /// not stated — fetches the calls, because the app cannot prove they are current.
    ///
    /// **Then compares what came back.** A stamp can move while the calls do not, so a successful read
    /// of the same list is still nothing newer. A read that failed is never a skip.
    public func refresh() async -> RefreshOutcome {
        isRefreshing = true
        defer { isRefreshing = false }

        let stamp = await readStamp()

        // The proof: the Service is still on the write the calls were read under.
        if let stamp, let asOf, stamp == asOf {
            return .skipped
        }

        let before = receivedCalls
        let didRead = await readCalls(under: stamp)

        guard didRead, let after = receivedCalls, after == before else {
            return .refreshed
        }
        return .skipped
    }

    /// The Service's latest stamp, if the layer will state it.
    ///
    /// A failure and an omitted stamp are both `nil`: either way the app cannot prove the calls are
    /// current, so the refresh fetches. Neither is something the reader needs to be told — the reader's
    /// business is the calls.
    private func readStamp() async -> Date? {
        do {
            return try await fetchStamp()
        } catch {
            return nil
        }
    }

    /// The calls themselves, and the stamp they are read under.
    ///
    /// A failed **calls** read leaves the calls and their stamp untouched, so the line keeps saying how
    /// old what is on screen actually is. A successful read records the stamp it was made under — `nil`
    /// when the Service stated none, because then the write those calls came from is unknown.
    @discardableResult
    private func readCalls(under stamp: Date?) async -> Bool {
        do {
            receivedCalls = try await fetch()
            asOf = stamp
            lastReadAt = now()
            failureMessage = nil
            isShowingStaleResult = false
            return true
        } catch {
            guard receivedCalls == nil else {
                isShowingStaleResult = true
                return false
            }
            failureMessage = "The police calls could not be loaded.\n\(error.localizedDescription)"
            return false
        }
    }

    /// The sentence for a refresh that was skipped.
    ///
    /// It names the as-of — the stamp the calls on screen were read under, which is the same value and
    /// the same shape the status line leads with, so the alert and the line cannot say different things.
    /// It does not name the Service's newest stamp, which can belong to a write the screen has not
    /// fetched.
    public var nothingNewerMessage: String {
        guard let asOf else {
            return "Nothing newer than the calls already on screen."
        }
        return "Nothing newer than \(DispatchTimestamp.publishedStamp(asOf))."
    }

    /// The line above the calls: the as-of of what is on screen, and what is happening to them.
    ///
    /// **"TPS data as of", in the fire line's shape and on the fire line's clock.** The time is the
    /// Service's stamp for the calls on screen — the write they were read under, not the Service's
    /// newest write — and it is written the way the City writes its own: `2026-10-05 12:54:19`, on
    /// Toronto's clock, not the reader's and not in the reader's 12- or 24-hour setting. A reader
    /// comparing this screen with the fire one should not have to work out that two lines in the same
    /// place are in two shapes.
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
        let asOfText = asOf.map { DispatchTimestamp.publishedStamp($0) } ?? "an unknown time"
        let base = "TPS data as of \(asOfText)"

        if isShowingStaleResult {
            return FeedStatus(text: "\(base) · showing the last result", isStale: true)
        }
        if isRefreshing {
            return FeedStatus(text: "\(base) · checking…", isStale: false)
        }
        return FeedStatus(text: base, isStale: false)
    }
}
