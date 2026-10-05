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

/// The police feed's state: what it holds after a read, what the gate lets through, and what it says.
///
/// Nothing here touches the network or the real clock — all three inputs are injected — so no test
/// waits on somebody else's service to decide whether it passes.
@MainActor
@Suite("Police call feed")
struct PoliceCallFeedTests {

    /// 16:54:19 UTC, when the feed reads, and when the Service last wrote.
    private static let readAt = Date(timeIntervalSince1970: 1_791_219_259)

    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

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

        let line = feed.status(format: .twentyFourHour, calendar: Self.utc)
        #expect(line.text == "TPS data as of 16:54 · showing the last result")
        #expect(line.isStale)
    }

    // MARK: - The gate, before the fetch

    @Test("inside the Service's interval, the calls are not asked for at all")
    func insideTheIntervalTheCallsAreNotFetched() async {
        // The heart of it: five minutes after the Service wrote, there is provably nothing new, so
        // the request must not happen. The count is what proves it did not.
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        let outcome = await feed.refresh()
        #expect(outcome == .skipped)
        let requests = await service.requestCount
        #expect(requests == 1, "the one request was the load, not the refresh")
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
        let feed = Self.feed(failingCalls: URLError(.timedOut))

        let outcome = await feed.refresh()
        #expect(outcome == .refreshed)
        #expect(feed.failureMessage != nil)
        #expect(feed.calls == nil)
    }

    // MARK: - The line

    @Test("says when the Service last published, in the reader's clock")
    func saysWhenTheServiceLastPublished() async {
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(
            feed.status(format: .twentyFourHour, calendar: Self.utc).text
                == "TPS data as of 16:54"
        )
        #expect(
            feed.status(format: .twelveHour, calendar: Self.utc).text
                == "TPS data as of 4:54 PM"
        )
        #expect(!feed.status(format: .twelveHour, calendar: Self.utc).isStale)
    }

    @Test("with no stamp, the line says so rather than inventing one")
    func anUnknownStampIsSaidToBeUnknown() async {
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service, publishedAt: nil)
        await feed.load()

        #expect(
            feed.status(format: .twentyFourHour, calendar: Self.utc).text
                == "TPS data as of an unknown time"
        )
    }

    // MARK: - What the alert says

    @Test("the sentence for a skip names the Service's own time")
    func nothingNewerNamesTheServicesTime() async {
        let service = CallsService([[Self.call(1)]])
        let feed = Self.feed(readingCalls: service)
        await feed.load()

        #expect(
            feed.nothingNewerMessage(format: .twentyFourHour, calendar: Self.utc)
                == "Nothing newer than 16:54."
        )
        #expect(
            feed.nothingNewerMessage(format: .twelveHour, calendar: Self.utc)
                == "Nothing newer than 4:54 PM."
        )
    }
}
