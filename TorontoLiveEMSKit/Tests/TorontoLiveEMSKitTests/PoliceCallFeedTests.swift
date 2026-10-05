import Foundation
import Testing

import TorontoLiveEMSKit

/// A fetch that succeeds once and fails after that.
///
/// An actor rather than a captured `var`, because the injected closure is `@Sendable` and anything
/// it shares has to be safe to share. This is what makes the stale case reachable: a feed with
/// something on screen whose next attempt fails.
private actor FlakyFetch {

    private var hasSucceeded = false
    private let calls: [PoliceCall]

    init(calls: [PoliceCall]) {
        self.calls = calls
    }

    func call() throws -> [PoliceCall] {
        guard !hasSucceeded else { throw URLError(.timedOut) }
        hasSucceeded = true
        return calls
    }
}

/// Answers in order, so a refresh can come back with something that was not there before — and then
/// with nothing at all, which is what a quiet four-hour window looks like.
private actor ChangingFetch {

    private var responses: [[PoliceCall]]

    init(_ responses: [[PoliceCall]]) {
        self.responses = responses
    }

    func call() -> [PoliceCall] {
        responses.isEmpty ? [] : responses.removeFirst()
    }
}

/// The police feed's state: what it holds after a read, after a failure, what a refresh makes of it,
/// and what it says.
///
/// Nothing here touches the network or the real clock — both are injected — so no test waits on
/// somebody else's service to decide whether it passes.
@MainActor
@Suite("Police call feed")
struct PoliceCallFeedTests {

    /// 16:54:19 UTC, when the feed reads.
    private static let readAt = Date(timeIntervalSince1970: 1_791_219_259)

    /// 16:41:19 UTC, thirteen minutes before the read — the newest call any fixture publishes.
    ///
    /// Deliberately *not* the read instant. If the two were the same the status line would say the
    /// same clock time twice, which a reader would take for a fault, and the test would be asserting
    /// that fault rather than the sentence.
    private static let newestCallAt = readAt.addingTimeInterval(-13 * 60)

    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private static func call(_ objectID: Int) -> PoliceCall {
        PoliceCall(
            objectID: objectID,
            occurrenceTime: newestCallAt,
            division: "D14",
            latitude: 43.66,
            longitude: -79.42,
            callTypeCode: "PERGU",
            callType: "PERSON WITH A GUN",
            crossStreets: "CHRISTIE ST - BLOOR ST W"
        )
    }

    private static func feed(
        fetching calls: @escaping @Sendable () async throws -> [PoliceCall]
    ) -> PoliceCallFeed {
        PoliceCallFeed(fetch: calls, now: { readAt })
    }

    // MARK: - Reading

    @Test("holds the calls, and records when it read them")
    func loadHoldsTheCalls() async {
        let feed = Self.feed(fetching: { [Self.call(1), Self.call(2)] })
        await feed.load()

        #expect(feed.calls?.count == 2)
        #expect(feed.lastReadAt == Self.readAt)
        #expect(feed.failureMessage == nil)
        #expect(!feed.isShowingStaleResult)
        #expect(!feed.isRefreshing, "the flag is a transient state, not a result")
    }

    @Test("a first failure is explained, and there is nothing to show")
    func firstFailureIsExplained() async {
        let feed = Self.feed(fetching: { throw URLError(.notConnectedToInternet) })
        await feed.load()

        #expect(feed.calls == nil)
        #expect(feed.failureMessage?.contains("could not be loaded") == true)
        #expect(!feed.isShowingStaleResult, "there is no last result to be showing")
    }

    @Test("a later failure keeps the calls and says they are old")
    func laterFailureKeepsTheLastResult() async {
        let flaky = FlakyFetch(calls: [Self.call(1)])
        let feed = Self.feed(fetching: { try await flaky.call() })

        await feed.load()
        #expect(feed.calls?.count == 1)
        #expect(feed.failureMessage == nil)

        // The case that matters: something is on screen and the next attempt fails.
        await feed.load()
        #expect(feed.calls?.count == 1, "the calls stay")
        #expect(feed.failureMessage == nil, "the message does not replace them")
        #expect(feed.isShowingStaleResult, "the line says they are old instead")

        let line = feed.status(format: .twentyFourHour, calendar: Self.utc)
        #expect(line.text == "Newest call 16:41 · read at 16:54 · showing the last result")
        #expect(line.isStale)
    }

    // MARK: - The gate, after the fact

    @Test("a refresh that brings back the same calls says nothing is newer")
    func unchangedCallsAreASkip() async {
        let feed = Self.feed(fetching: { [Self.call(1), Self.call(2)] })
        await feed.load()

        #expect(feed.calls?.count == 1)
        let outcome = await feed.refresh()
        #expect(outcome == .skipped)
        let again = await feed.refresh()
        #expect(again == .skipped, "and again, because nothing has changed")
    }

    @Test("a refresh that brings back a call that was not there is not a skip")
    func aNewCallIsNotASkip() async {
        let changing = ChangingFetch([[Self.call(1)], [Self.call(1), Self.call(2)]])
        let feed = Self.feed(fetching: { await changing.call() })

        await feed.load()
        #expect(feed.calls?.count == 1)
        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.calls?.count == 2)
    }

    @Test("a call disappearing is a change too")
    func aRemovedCallIsNotASkip() async {
        // The window rolls, so the ordinary case is a call dropping off the end as much as one
        // arriving. A comparison that only noticed additions would call a vanished call "no change".
        let changing = ChangingFetch([[Self.call(1), Self.call(2)], [Self.call(2)]])
        let feed = Self.feed(fetching: { await changing.call() })

        await feed.load()
        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.calls?.count == 1)
    }

    @Test("a failed refresh is never 'nothing newer'")
    func aFailedRefreshIsNotASkip() async {
        // The point of gating after the fact rather than before it: `load()` leaves the last good
        // calls in place when an attempt fails, so an unchanged array proves nothing. Reporting it
        // as a skip would turn a dropped connection into reassurance.
        let flaky = FlakyFetch(calls: [Self.call(1)])
        let feed = Self.feed(fetching: { try await flaky.call() })

        await feed.load()
        let outcome = await feed.refresh()
        #expect(outcome == .refreshed, "the attempt failed, so nothing was established")
        #expect(feed.isShowingStaleResult, "and the line says so")
    }

    @Test("a first failed refresh, with nothing on screen, is not a skip either")
    func aFirstFailedRefreshIsNotASkip() async {
        let feed = Self.feed(fetching: { throw URLError(.timedOut) })

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.failureMessage != nil)
        #expect(feed.calls == nil)
    }

    // MARK: - The line

    @Test("says it is reading before the first result")
    func readingBeforeTheFirstResult() {
        let feed = Self.feed(fetching: { [] })
        #expect(feed.status(format: .twelveHour).text == "Reading…")
    }

    @Test("leads with the Service's newest call and follows with our own read")
    func saysTheNewestCallAndWhenItRead() async {
        let feed = Self.feed(fetching: { [Self.call(1)] })
        await feed.load()

        #expect(
            feed.status(format: .twentyFourHour, calendar: Self.utc).text
                == "Newest call 16:41 · read at 16:54"
        )
        #expect(
            feed.status(format: .twelveHour, calendar: Self.utc).text
                == "Newest call 4:41 PM · read at 4:54 PM"
        )
        #expect(!feed.status(format: .twelveHour, calendar: Self.utc).isStale)
    }

    @Test("with no calls yet, the line still says when it read")
    func anEmptyWindowStillSaysWhenItRead() async {
        // A quiet four hours is not a failure and not a blank: the Service answered, and the answer
        // was that nothing happened. The read time is then the whole of what there is to say.
        let feed = Self.feed(fetching: { [] })
        await feed.load()

        #expect(
            feed.status(format: .twentyFourHour, calendar: Self.utc).text == "Read at 16:54"
        )
    }

    // MARK: - What the alert says

    @Test("the sentence for a skip names the newest call, in the reader's clock")
    func nothingNewerNamesTheNewestCall() async {
        let feed = Self.feed(fetching: { [Self.call(1)] })
        await feed.load()

        #expect(
            feed.nothingNewerMessage(format: .twentyFourHour, calendar: Self.utc)
                == "Nothing newer than 16:41."
        )
        #expect(
            feed.nothingNewerMessage(format: .twelveHour, calendar: Self.utc)
                == "Nothing newer than 4:41 PM."
        )
    }
}
