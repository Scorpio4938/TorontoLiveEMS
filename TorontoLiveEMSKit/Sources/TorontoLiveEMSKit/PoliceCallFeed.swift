import Foundation
import Observation

/// The police calls the app is showing, and everything about how they got here.
///
/// **The fire feed's shape, with one deliberate difference: there is no gate.** `IncidentFeed` can
/// skip a refresh because the City publishes the timestamp of its own last republish, and between
/// two of its five-minute boundaries there is provably nothing to fetch. This service publishes no
/// such timestamp — its layer carries no time info at all, and asking for the layer's edit date
/// would be a second request to learn when to make the first. So a refresh here always fetches, and
/// the politeness rule is the reader's: once at launch, once per explicit tap, and never on a timer.
///
/// **The age it shows is ours, not the Service's.** There is no published tick to quote, so the
/// status line says when the app last read the calls — which is the one thing the app actually
/// knows — rather than implying it knows when the Service republished.
///
/// `@Observable` and `@MainActor`, the same shape as `IncidentFeed`, passed as an ordinary property
/// and **never through `@Environment`**, where a missing key traps rather than degrading.
///
/// **It reads neither the clock nor the network directly.** Both are injected, so the status
/// sentence can be tested at its boundaries without waiting for anybody's server, and no test
/// touches a service that never offered one.
@MainActor
@Observable
public final class PoliceCallFeed {

    /// The most recent calls, or nothing if the first fetch has not succeeded.
    public private(set) var calls: [PoliceCall]?

    /// When the calls were last read.
    ///
    /// Kept because it is what the status line reports and what a reader judges currency by. It is
    /// the app's own clock — see the note above on why the Service's is not available.
    public private(set) var lastReadAt: Date?

    /// Why there are no calls, in a sentence fit to show. Only set when there is nothing to show in
    /// its place.
    public private(set) var failureMessage: String?

    /// A fetch is in flight. Said in the status line rather than on the button, so the button keeps
    /// its untouched appearance.
    public private(set) var isRefreshing = false

    /// What is on screen is the last good result and the newest attempt failed. Distinct from
    /// `failureMessage`: this one means there is still something to read.
    public private(set) var isShowingStaleResult = false

    private let fetch: @Sendable () async throws -> [PoliceCall]
    private let now: @Sendable () -> Date

    public init(
        fetch: @escaping @Sendable () async throws -> [PoliceCall] = {
            try await CallsForServiceClient().calls()
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetch = fetch
        self.now = now
    }

    /// Fetches, and holds on to whatever comes back.
    ///
    /// A failure with nothing on screen is said in place of the list. A failure *with* something on
    /// screen keeps it and flags it stale, because emptying a screen a reader is using is worse than
    /// telling them it is old.
    public func load() async {
        isRefreshing = true
        defer { isRefreshing = false }

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

    /// The line above the calls: when they were read, and what is happening to them.
    ///
    /// **The clock format is an argument rather than a stored property.** The fire feed's status is a
    /// property because the City's own timestamp is a string it can quote; this one has to *format* a
    /// date, and the format belongs to the reader's setting — which is the app target's business, not
    /// the package's. Passing it keeps the sentence here, where it can be tested, and keeps the
    /// preference there.
    ///
    /// The calendar is an argument for the same reason and one more: a test that formats "now" cannot
    /// pin the answer without one, and an assertion that only holds in one time zone is not an
    /// assertion.
    ///
    /// No case for having read nothing yet: the screens say that with a spinner and a sentence in the
    /// list's place, which is where a reader looks for it — the same judgement `IncidentFeed` makes.
    public func status(
        format: DispatchTimeFormat,
        calendar: Calendar = .current
    ) -> FeedStatus {
        guard let lastReadAt else {
            return FeedStatus(text: "Reading…", isStale: false)
        }

        // "Read at", not "as of". The Service publishes no republish time, so a phrase that implied
        // one would be claiming knowledge the app does not have — where the fire feed *can* say
        // "City data as of", because the City publishes exactly that.
        let clock = DispatchTimestamp.clockTime(lastReadAt, format: format, calendar: calendar)
        let base = "Read at \(clock)"

        if isShowingStaleResult {
            return FeedStatus(text: "\(base) · showing the last result", isStale: true)
        }
        if isRefreshing {
            return FeedStatus(text: "\(base) · checking…", isStale: false)
        }
        return FeedStatus(text: base, isStale: false)
    }
}
