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

/// The police feed's state: what it holds after a read, after a failure, and what it says.
///
/// Nothing here touches the network or the real clock — both are injected — so no test waits on
/// somebody else's service to decide whether it passes.
@MainActor
@Suite("Police call feed")
struct PoliceCallFeedTests {

    /// 16:54:19 UTC, the instant the fixture's newest call carries.
    private static let readAt = Date(timeIntervalSince1970: 1_791_219_259)

    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private static func call(_ objectID: Int) -> PoliceCall {
        PoliceCall(
            objectID: objectID,
            occurrenceTime: readAt,
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
        #expect(line.text == "Read at 16:54 · showing the last result")
        #expect(line.isStale)
    }

    // MARK: - The line

    @Test("says it is reading before the first result")
    func readingBeforeTheFirstResult() {
        let feed = Self.feed(fetching: { [] })
        #expect(feed.status(format: .twelveHour).text == "Reading…")
    }

    @Test("says when it read the calls, in the reader's clock")
    func saysWhenItRead() async {
        let feed = Self.feed(fetching: { [Self.call(1)] })
        await feed.load()

        #expect(
            feed.status(format: .twentyFourHour, calendar: Self.utc).text == "Read at 16:54"
        )
        #expect(
            feed.status(format: .twelveHour, calendar: Self.utc).text == "Read at 4:54 PM"
        )
        #expect(!feed.status(format: .twelveHour, calendar: Self.utc).isStale)
    }
}
