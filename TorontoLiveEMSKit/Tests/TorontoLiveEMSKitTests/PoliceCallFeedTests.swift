import Foundation
import Testing

import TorontoLiveEMSKit

/// The calls side of the service: answers in order, counts what it was asked, and can start failing.
///
/// An actor because the injected closure is `@Sendable`. The count is the point — a refresh with no
/// intervening write must not fetch the calls, though it does ask the Service for its stamp.
private actor CallsService {

    private var responses: [[PoliceCall]]
    private var failsFrom: Int?
    private(set) var requestCount = 0

    init(_ responses: [[PoliceCall]]) {
        self.responses = responses
    }

    /// Answer this request and every one after it by failing.
    func failFrom(request number: Int) {
        failsFrom = number
    }

    func next() throws -> [PoliceCall] {
        requestCount += 1
        if let failsFrom, requestCount >= failsFrom {
            throw URLError(.timedOut)
        }
        return responses.isEmpty ? [] : responses.removeFirst()
    }
}

/// The metadata side of the service: answers with the Service's stamps, and counts being asked.
///
/// A sequence rather than one value, because the defect was about the stamp *moving* between a read
/// and a refresh. The last stamp repeats, so a constant is written as one element and a change as two.
private actor StampService {

    private var stamps: [Date?]
    private(set) var requestCount = 0

    init(_ stamps: [Date?]) {
        self.stamps = stamps
    }

    init(_ stamp: Date?) {
        self.stamps = [stamp]
    }

    func next() -> Date? {
        requestCount += 1
        guard let head = stamps.first else {
            return nil
        }
        if stamps.count > 1 {
            stamps.removeFirst()
        }
        return head
    }
}

/// The police feed's state: what it holds after a read, when it skips, and what it says.
///
/// Nothing here touches the network or the real clock — the inputs are injected — so no test waits on
/// somebody else's service to decide whether it passes.
@MainActor
@Suite("Police call feed")
struct PoliceCallFeedTests {

    /// 16:54:19 UTC, when the feed reads, and when the Service last wrote.
    private static let readAt = Date(timeIntervalSince1970: 1_791_219_259)

    private static func call(_ objectID: Int, minutesAgo: Double = 13) -> PoliceCall {
        PoliceCall(
            objectID: objectID,
            // Deliberately not the read instant: the calls and the Service's clock are different
            // things, and a fixture where they coincide would hide a line that confused the two.
            occurrenceTime: readAt.addingTimeInterval(-minutesAgo * 60),
            division: "D14",
            latitude: 43.66,
            longitude: -79.42,
            callTypeCode: "PERGU",
            callType: "PERSON WITH A GUN",
            crossStreets: "CHRISTIE ST - BLOOR ST W"
        )
    }

    private static func feed(
        readingCalls service: CallsService,
        stamp: Date? = readAt,
        now: Date = readAt
    ) -> PoliceCallFeed {
        PoliceCallFeed(
            fetch: { try await service.next() },
            fetchStamp: { stamp },
            now: { now }
        )
    }

    private static func feed(
        readingCalls service: CallsService,
        stamps: StampService,
        now: Date = readAt
    ) -> PoliceCallFeed {
        PoliceCallFeed(
            fetch: { try await service.next() },
            fetchStamp: { await stamps.next() },
            now: { now }
        )
    }

    private static func feed(failingCalls error: Error = URLError(.notConnectedToInternet)) -> PoliceCallFeed {
        PoliceCallFeed(
            fetch: { throw error },
            fetchStamp: { readAt },
            now: { readAt }
        )
    }

    // MARK: - Reading

    @Test("holds the calls, records the as-of and its own read time")
    func loadHoldsTheCalls() async {
        let service = CallsService([[Self.call(1), Self.call(2)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(feed.calls?.count == 2)
        #expect(feed.asOf == Self.readAt, "the stamp the calls were read under")
        #expect(feed.lastReadAt == Self.readAt, "and ours, which is no longer on screen")
        #expect(feed.failureMessage == nil)
        #expect(!feed.isShowingStaleResult)
        #expect(!feed.isRefreshing, "the flag is a transient state, not a result")
        let requests = await service.requestCount
        #expect(requests == 1)
    }

    @Test("a first failure is explained, and there is nothing to show")
    func firstFailureIsExplained() async {
        let feed = Self.feed(failingCalls: URLError(.notConnectedToInternet))
        await feed.load()

        #expect(feed.calls == nil)
        #expect(feed.asOf == nil, "nothing was read, so there is no as-of to quote")
        #expect(feed.failureMessage?.contains("could not be loaded") == true)
        #expect(!feed.isShowingStaleResult, "there is no last result to be showing")
    }

    @Test("a later failure keeps the calls and says they are old")
    func laterFailureKeepsTheLastResult() async {
        let service = CallsService([[Self.call(1)]])
        await service.failFrom(request: 2)
        let feed = Self.feed(readingCalls: service)

        await feed.load()
        #expect(feed.calls?.count == 1)
        #expect(feed.failureMessage == nil)

        // The case that matters: something is on screen and the next attempt fails.
        await feed.load()
        #expect(feed.calls?.count == 1, "the calls stay")
        #expect(feed.failureMessage == nil, "the message does not replace them")
        #expect(feed.isShowingStaleResult, "the line says they are old instead")

        let line = feed.status
        #expect(line.text == "TPS data as of 2026-10-05 12:54:19 · showing the last result")
        #expect(line.isStale)
    }

    // MARK: - Ordering

    @Test("lists the most recent call first, whatever order the Service returned")
    func newestCallIsFirst() async {
        // Returned out of order, as a source the app does not control is entitled to. Before this, the
        // page showed whichever end the Service's response happened to start at.
        let service = CallsService([[
            Self.call(3, minutesAgo: 30),
            Self.call(1, minutesAgo: 5),
            Self.call(2, minutesAgo: 13),
        ]])
        let feed = Self.feed(readingCalls: service)

        await feed.load()

        #expect(feed.calls?.map(\.objectID) == [1, 2, 3])
    }

    // MARK: - The skip and the fetch

    @Test("a refresh with nothing written fetches no calls, but still asks")
    func unchangedStampSkipsTheCalls() async {
        // The old test asserted that a tap inside twenty minutes asked nobody — which was the defect.
        // The app could not know a write had not landed, because it never asked. It now asks every
        // time, and spends no calls request when the stamp proves the copy is current.
        let calls = CallsService([[Self.call(1)]])
        let stamps = StampService(Self.readAt)
        let feed = Self.feed(readingCalls: calls, stamps: stamps)
        await feed.load()

        let loadedCalls = await calls.requestCount
        let loadedStamps = await stamps.requestCount
        #expect(loadedCalls == 1)
        #expect(loadedStamps == 1, "the load reads the Service's stamp, unconditionally")

        let outcome = await feed.refresh()
        #expect(outcome == .skipped)

        let askedCalls = await calls.requestCount
        let askedStamps = await stamps.requestCount
        #expect(askedCalls == loadedCalls, "an unchanged stamp proves the calls are current")
        #expect(askedStamps == loadedStamps + 1, "but the Service is always asked")
    }

    @Test("a write after the last read is fetched on the next refresh")
    func aNewWriteIsFetched() async {
        // The defect: the Service's stamp moved to a write the screen had not fetched, and the app
        // refused to fetch it because it treated the new stamp as if it belonged to the old calls.
        let calls = CallsService([[Self.call(1)], [Self.call(1), Self.call(2)]])
        let movedTo = Self.readAt.addingTimeInterval(20 * 60)
        let stamps = StampService([Self.readAt, movedTo])
        let feed = Self.feed(readingCalls: calls, stamps: stamps)
        await feed.load()
        #expect(feed.asOf == Self.readAt)

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.calls?.count == 2)
        #expect(feed.asOf == movedTo)
        let requests = await calls.requestCount
        #expect(requests == 2, "the stamp moved, so the calls were fetched")
    }

    @Test("a stamp that moves while the calls do not is still nothing newer")
    func aMovedStampWithTheSameCallsIsASkip() async {
        // The post-fetch comparison: the Service edited the layer, the query returned the same list, and
        // the reader is told nothing newer rather than shown a refresh that found something.
        let calls = CallsService([[Self.call(1)], [Self.call(1)]])
        let movedTo = Self.readAt.addingTimeInterval(20 * 60)
        let stamps = StampService([Self.readAt, movedTo])
        let feed = Self.feed(readingCalls: calls, stamps: stamps)
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .skipped, "the calls that came back are the ones already on screen")
        #expect(feed.asOf == movedTo, "they were read under the newer stamp, so that is their as-of")
        #expect(feed.status.text == "TPS data as of 2026-10-05 13:14:19")
        #expect(feed.nothingNewerMessage == "Nothing newer than 2026-10-05 13:14:19.")
        let requests = await calls.requestCount
        #expect(requests == 2, "the stamp moved, so the calls were fetched")
    }

    @Test("a call disappearing is a change too")
    func aRemovedCallIsNotASkip() async {
        // The window rolls, so the ordinary case is a call dropping off the end as much as one
        // arriving. A comparison that only noticed additions would call a vanished call "no change".
        let service = CallsService([[Self.call(1), Self.call(2)], [Self.call(2)]])
        let stamps = StampService([Self.readAt, Self.readAt.addingTimeInterval(20 * 60)])
        let feed = Self.feed(readingCalls: service, stamps: stamps)
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.calls?.count == 1)
    }

    @Test("with no stamp from the Service, the calls are fetched rather than skipped")
    func noStampMeansFetch() async {
        // A metadata response we could not read must never block a refresh: without a stamp there is no
        // proof the calls are current, so the app asks for them.
        let service = CallsService([[Self.call(1)], [Self.call(1), Self.call(2)]])
        let stamps = StampService(nil)
        let feed = Self.feed(readingCalls: service, stamps: stamps)
        await feed.load()
        #expect(feed.asOf == nil)

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        let requests = await service.requestCount
        #expect(requests == 2)
        let askedStamps = await stamps.requestCount
        #expect(askedStamps == 2, "it was asked both times")
    }

    @Test("a failed read is never 'nothing newer'")
    func aFailedReadIsNotASkip() async {
        // The stamp moved, so the calls are fetched — and that attempt failing proves nothing about
        // whether what is on screen is current. The as-of stays with the calls that are still there.
        let service = CallsService([[Self.call(1)]])
        await service.failFrom(request: 2)
        let stamps = StampService([Self.readAt, Self.readAt.addingTimeInterval(20 * 60)])
        let feed = Self.feed(readingCalls: service, stamps: stamps)
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed, "the attempt failed, so nothing was established")
        #expect(feed.isShowingStaleResult, "and the line says so")
        #expect(feed.asOf == Self.readAt, "the as-of stays with the calls on screen")
        #expect(feed.status.text == "TPS data as of 2026-10-05 12:54:19 · showing the last result")
    }

    @Test("a first failed refresh, with nothing on screen, is not a skip either")
    func aFirstFailedRefreshIsNotASkip() async {
        // A refresh always asks the Service, so a first failure is reachable without a load.
        let feed = PoliceCallFeed(
            fetch: { throw URLError(.timedOut) },
            fetchStamp: { Self.readAt },
            now: { Self.readAt }
        )

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.failureMessage != nil)
        #expect(feed.calls == nil)
        #expect(feed.asOf == nil, "nothing was read, so there is no as-of")
    }

    // MARK: - The line

    @Test("says the as-of the calls were read under, in the City's own shape and on its clock")
    func saysTheAsOf() async {
        // **Not the reader's clock and not the reader's 12- or 24-hour setting.** The fire feed's line
        // beside it quotes the City's `2026-10-05 14:00:02`, and two lines a reader compares should be
        // in one shape on one clock. The fixture's 16:54:19 UTC is 12:54:19 in Toronto.
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(feed.status.text == "TPS data as of 2026-10-05 12:54:19")
        #expect(!feed.status.isStale)
    }

    @Test("with no stamp, the line says so rather than inventing one")
    func anUnknownStampIsSaidToBeUnknown() async {
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service, stamp: nil)
        await feed.load()

        #expect(feed.status.text == "TPS data as of an unknown time")
    }

    // MARK: - What the alert says

    @Test("the sentence for a skip names the as-of, in the same shape")
    func nothingNewerNamesTheAsOf() async {
        // The same value in the same shape as the line, so the alert and the line cannot describe two
        // different times.
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(feed.nothingNewerMessage == "Nothing newer than 2026-10-05 12:54:19.")
    }
}
