import Foundation
import Observation

/// The police calls the app is showing, and everything about how they got here.
///
/// **The fire feed's shape, with one difference that is forced rather than chosen.** `IncidentFeed`
/// can decline to ask at all: the City's republish tick arrives *inside* the XML it already fetches,
/// so between two of its five-minute boundaries there is provably nothing to ask for. This Service
/// publishes a last-edit time too — the layer's `editingInfo.dataLastEditDate`, measured moving —
/// but a `query` cannot be asked for it: it comes in a separate 10.5 KB metadata response, against
/// 22.7 KB for the calls themselves. Declining to ask would therefore cost about half a fetch every
/// time, and more than a fetch when something *had* changed. So the gate is *after* the fact: fetch,
/// compare, and say "nothing newer" only when the calls that came back are exactly the ones already
/// on screen. That is free, and it is a fact rather than an inference. See ADR-0006.
///
/// **Two times, and only one of them is the Service's.** The line says when the newest published call
/// happened, which is the only "as of" this feed can honestly state, and when the app read it. It
/// does not quote the Service's own edit time: that would cost a request on every refresh, and it
/// names a moment *later* than the newest call — deleting an expired call edits the layer too.
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

    /// Refreshes, and answers whether what came back was already on screen.
    ///
    /// **A gate after the fact, because this feed has no gate before it.** The reasoning is in the
    /// type's documentation above; the short version is that asking the Service whether anything
    /// changed costs about as much as asking for the calls.
    ///
    /// A read that **failed** is not "nothing newer". `load()` keeps the last good calls in place
    /// when an attempt fails, so an unchanged array is only evidence when the read actually happened
    /// — otherwise a dropped connection would be reported to the reader as reassurance.
    public func refresh() async -> RefreshOutcome {
        let before = calls
        await load()

        guard failureMessage == nil,
              !isShowingStaleResult,
              let after = calls,
              after != before
        else {
            return .refreshed
        }
        return .skipped
    }

    /// The newest instant the Service published, which is the only "as of" this feed can state.
    private var newestCallAt: Date? {
        calls?.map(\.occurrenceTime).max()
    }

    /// The sentence for a refresh that came back with exactly what was already there.
    ///
    /// Fire's version names the City's tick, because fire has a tick. This one names the newest call
    /// it holds — the same thing the status line leads with, and the only time the Service actually
    /// published. A method rather than a property for `status`'s reason: it formats a date, and the
    /// format is the reader's setting rather than the package's.
    public func nothingNewerMessage(
        format: DispatchTimeFormat,
        calendar: Calendar = .current
    ) -> String {
        guard let newest = newestCallAt else {
            return "Nothing newer than the calls already on screen."
        }
        let clock = DispatchTimestamp.clockTime(newest, format: format, calendar: calendar)
        return "Nothing newer than \(clock)."
    }

    /// The line above the calls: what the Service last published, and when the app read it.
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
    /// **"Newest call", not "as of".** The Service publishes no republish time in anything the app
    /// fetches — the layer's edit time is a request of its own, and it names a moment later than the
    /// newest call anyway — so the honest "as of" is the newest call the Service published. What the
    /// reader most needs beside it is when *this app* looked, which is the one thing it knows first
    /// hand, and which the fire feed cannot say because it is busy quoting the City.
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

        var parts: [String] = []
        let newest = newestCallAt.map {
            DispatchTimestamp.clockTime($0, format: format, calendar: calendar)
        }
        let read = DispatchTimestamp.clockTime(lastReadAt, format: format, calendar: calendar)

        // Two sentences in one line, and the first one has to stand on its own when there is nothing
        // to lead with: a quiet four hours leaves the read time as the whole of what there is to say,
        // and it must not arrive as "read at 16:54" in lower case as though something came before it.
        if let newest {
            parts.append("Newest call \(newest)")
            parts.append("read at \(read)")
        } else {
            parts.append("Read at \(read)")
        }

        if isShowingStaleResult {
            parts.append("showing the last result")
        } else if isRefreshing {
            parts.append("checking…")
        }

        return FeedStatus(text: parts.joined(separator: " · "), isStale: isShowingStaleResult)
    }
}
