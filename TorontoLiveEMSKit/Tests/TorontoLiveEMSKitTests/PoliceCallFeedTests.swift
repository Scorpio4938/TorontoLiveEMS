import Foundation
import Testing

import TorontoLiveEMSKit

/// The calls side of the service: answers in order, counts what it was asked, and can start failing.
///
/// An actor because the injected closure is `@Sendable`. The count is the point — the gate's whole
/// claim is that the calls are *not* asked for between two of the Service's writes, and a test that
/// only looked at the outcome could not tell that from a fetch that came back unchanged.
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

/// The metadata side of the service: answers with the Service's clock, and counts being asked.
///
/// Counted separately from the calls, because the gate makes two different claims: that the calls are
/// not fetched between two of the Service's writes, and that the Service is not *asked* whether it has
/// written either. The second is the one that used to cost a round trip.
private actor StampService {

    private let stamp: Date?
    private(set) var requestCount = 0

    init(_ stamp: Date?) {
        self.stamp = stamp
    }

    func next() -> Date? {
        requestCount += 1
        return stamp
    }
}

/// The police feed's state: what it holds after a read, what the gate lets through, and what it says.
///
/// Nothing here touches the network or the real clock — all three inputs are injected — so no test
/// waits on somebody else's service to decide whether it passes.
@MainActor
@Suite("Police call feed")
struct PoliceCallFeedTests {

    /// 16:54:19 UTC, when the feed reads, and when the Service last wrote.
    private static let readAt = Date(timeIntervalSince1970: 1_791_219_259)

    private static func call(_ objectID: Int) -> PoliceCall {
        PoliceCall(
            objectID: objectID,
            // Deliberately not the read instant: the calls and the Service's clock are different
            // things, and a fixture where they coincide would hide a line that confused the two.
            occurrenceTime: readAt.addingTimeInterval(-13 * 60),
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
        publishedAt stamp: Date? = readAt,
        now: Date = readAt
    ) -> PoliceCallFeed {
        PoliceCallFeed(
            fetch: { try await service.next() },
            fetchPublishedAt: { stamp },
            now: { now }
        )
    }

    private static func feed(failingCalls error: Error = URLError(.notConnectedToInternet)) -> PoliceCallFeed {
        PoliceCallFeed(
            fetch: { throw error },
            fetchPublishedAt: { readAt },
            now: { readAt }
        )
    }

    // MARK: - Reading

    @Test("holds the calls, records the Service's time and its own")
    func loadHoldsTheCalls() async {
        let service = CallsService([[Self.call(1), Self.call(2)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(feed.calls?.count == 2)
        #expect(feed.publishedAt == Self.readAt, "the Service's clock, quoted as stated")
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

    // MARK: - The gate, before the fetch

    @Test("inside the Service's interval, nobody is asked anything at all")
    func insideTheIntervalNobodyIsAsked() async {
        // **The test for the freeze.** The gate used to be made *after* asking the Service for its
        // clock, so a tap inside the window spent a network round trip learning what the app already
        // knew — and on a slow connection that was a spinner appearing to do nothing. Now the clock the
        // app holds decides, and neither request happens: the calls are not fetched, and the Service is
        // not asked whether it has written.
        let calls = CallsService([[Self.call(1)]])
        let stamps = StampService(Self.readAt)
        let feed = PoliceCallFeed(
            fetch: { try await calls.next() },
            fetchPublishedAt: { await stamps.next() },
            now: { Self.readAt }
        )
        await feed.load()

        let loadedCalls = await calls.requestCount
        let loadedStamp = await stamps.requestCount
        #expect(loadedCalls == 1)
        #expect(loadedStamp == 1, "the load reads the Service's clock, and does so unconditionally")

        let outcome = await feed.refresh()
        #expect(outcome == .skipped)

        let askedCalls = await calls.requestCount
        let askedStamp = await stamps.requestCount
        #expect(askedCalls == loadedCalls, "the calls are not fetched inside the window")
        #expect(askedStamp == loadedStamp, "and the Service is not asked either — which is the fix")
    }

    @Test("at the interval, the calls are asked for again")
    func afterTheIntervalTheCallsAreFetched() async {
        let service = CallsService([[Self.call(1)], [Self.call(1), Self.call(2)]])
        let feed = Self.feed(
            readingCalls: service,
            now: Self.readAt.addingTimeInterval(20 * 60)
        )
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        let requests = await service.requestCount
        #expect(requests == 2)
        #expect(feed.calls?.count == 2)
    }

    @Test("a late write is still nothing newer, and is asked for")
    func aLateWriteIsStillNothingNewer() async {
        // Twenty minutes is the Service's pace, not a promise. When the write is late the gate opens
        // and the same calls come back, which the comparison catches — so the reader is told the
        // truth rather than shown a refresh that "found something".
        let service = CallsService([[Self.call(1)], [Self.call(1)]])
        let feed = Self.feed(
            readingCalls: service,
            now: Self.readAt.addingTimeInterval(21 * 60)
        )
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .skipped, "asked, and the answer was that nothing had changed")
        let requests = await service.requestCount
        #expect(requests == 2, "but it was asked")
    }

    @Test("a call disappearing is a change too")
    func aRemovedCallIsNotASkip() async {
        // The window rolls, so the ordinary case is a call dropping off the end as much as one
        // arriving. A comparison that only noticed additions would call a vanished call "no change".
        let service = CallsService([[Self.call(1), Self.call(2)], [Self.call(2)]])
        let feed = Self.feed(
            readingCalls: service,
            now: Self.readAt.addingTimeInterval(21 * 60)
        )
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.calls?.count == 1)
    }

    @Test("with no stamp from the Service, the gate fails open")
    func noStampMeansNoGate() async {
        // A metadata response we could not read must never block a refresh: the reader would be
        // looking at old calls for ever, with nothing on screen to say why.
        let service = CallsService([[Self.call(1)], [Self.call(1), Self.call(2)]])
        let feed = Self.feed(readingCalls: service, publishedAt: nil)
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        let requests = await service.requestCount
        #expect(requests == 2)
    }

    @Test("a failed read is never 'nothing newer'")
    func aFailedReadIsNotASkip() async {
        // `readCalls()` keeps the last good calls when an attempt fails, so an unchanged array proves
        // nothing. Reporting it as a skip would turn a dropped connection into reassurance.
        let service = CallsService([[Self.call(1)]])
        await service.failFrom(request: 2)
        let feed = Self.feed(
            readingCalls: service,
            now: Self.readAt.addingTimeInterval(21 * 60)
        )
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed, "the attempt failed, so nothing was established")
        #expect(feed.isShowingStaleResult, "and the line says so")
    }

    @Test("a first failed refresh, with nothing on screen, is not a skip either")
    func aFirstFailedRefreshIsNotASkip() async {
        // The window has passed, so this refresh actually asks — which is the only way a failure can
        // be reached at all now.
        let feed = PoliceCallFeed(
            fetch: { throw URLError(.timedOut) },
            fetchPublishedAt: { Self.readAt },
            now: { Self.readAt.addingTimeInterval(21 * 60) }
        )

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.failureMessage != nil)
        #expect(feed.calls == nil)
    }

    // MARK: - The line

    @Test("says when the Service last published, in the City's own shape and on its clock")
    func saysWhenTheServiceLastPublished() async {
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
        let feed = Self.feed(readingCalls: service, publishedAt: nil)
        await feed.load()

        #expect(feed.status.text == "TPS data as of an unknown time")
    }

    // MARK: - What the alert says

    @Test("the sentence for a skip names the Service's own time, in the same shape")
    func nothingNewerNamesTheServicesTime() async {
        // The same value in the same shape as the line, so the alert and the line cannot describe two
        // different times.
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(feed.nothingNewerMessage == "Nothing newer than 2026-10-05 12:54:19.")
    }
}
