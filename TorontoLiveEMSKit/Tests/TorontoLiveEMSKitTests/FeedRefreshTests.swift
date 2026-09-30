import Foundation
import Testing
import TorontoLiveEMSKit

@Suite("Feed refresh")
struct FeedRefreshTests {

    /// 2026-09-30 00:00:02 Toronto local, as an absolute instant.
    ///
    /// Computed outside this codebase rather than derived the way `FeedRefresh` derives
    /// it, so these tests can disagree with the implementation.
    private static let tickEpoch: TimeInterval = 1_790_740_802
    private static let tick = "2026-09-30 00:00:02"

    private func at(_ secondsAfterTick: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: Self.tickEpoch + secondsAfterTick)
    }

    @Test("says nothing has been published in the minute after a tick")
    func nothingWithinTheInterval() {
        // Asking one minute after the City published cannot return anything new.
        #expect(!FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(60)))
        #expect(!FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(299)))
    }

    @Test("allows a refresh once the interval has elapsed")
    func allowsAfterTheInterval() {
        #expect(FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(300)))
        #expect(FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(301)))
        #expect(FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(3600)))
    }

    @Test("the interval is the five minutes the City publishes on")
    func intervalIsFiveMinutes() {
        #expect(FeedRefresh.interval == 300)
    }

    @Test("fails open when there is nothing to reason from")
    func failsOpen() {
        // A refresh should never be blocked by a value we could not read.
        #expect(FeedRefresh.mayHaveRefreshed(since: nil, now: at(1)))
        #expect(FeedRefresh.mayHaveRefreshed(since: "", now: at(1)))
        #expect(FeedRefresh.mayHaveRefreshed(since: "not a timestamp", now: at(1)))
        #expect(FeedRefresh.mayHaveRefreshed(since: "2026-09-30", now: at(1)))
    }

    @Test("reads the tick on the City's clock, not the reader's")
    func readsTorontoLocalTime() {
        // The same wall-clock text is four hours earlier in UTC, so a reader in London
        // asking at 04:01 UTC is asking one minute after the City published — and must be
        // told there is nothing new.
        #expect(!FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(59)))
        #expect(!FeedRefresh.mayHaveRefreshed(since: Self.tick, now: at(60)))
    }
}
