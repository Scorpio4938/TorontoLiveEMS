import Foundation
import Testing
import TorontoLiveEMSKit

/// Counts how many times the feed was actually asked for a snapshot.
///
/// An actor rather than a captured `var`, because `IncidentFeed.fetch` is `@Sendable` and
/// anything it shares has to be safe to share. Every test that asserts *whether* a refresh
/// happened — the whole point of the five-minute gate — asks this.
private actor FetchCounter {

    private(set) var count = 0

    func record() {
        count += 1
    }
}

/// A place to write down what the status line said while a fetch was running.
private actor StatusRecorder {

    private(set) var seen: [String] = []

    func record(_ text: String) {
        seen.append(text)
    }
}

/// Holds the feed so a fetch can look at it.
///
/// A fetch cannot close over the very object it is being handed to — the reference does not
/// exist until the initialiser returns. A `@MainActor` class is safe to share, so this is the
/// box that gets captured instead, and it is filled in immediately afterwards.
@MainActor
private final class FeedBox {
    var feed: IncidentFeed?
}

@Suite("Incident feed")
@MainActor
struct IncidentFeedTests {

    /// 2026-09-30 00:00:02 Toronto local, as an absolute instant.
    ///
    /// The same instant `FeedRefreshTests` uses, and for the same reason: computed outside this
    /// codebase rather than derived the way `FeedRefresh` derives it, so a test and an
    /// implementation cannot be wrong together.
    ///
    /// Both helpers are `nonisolated` so that the `@Sendable` fetch closures below can call
    /// them. The suite is `@MainActor`, and members inherit that unless told otherwise.
    private static let tickEpoch: TimeInterval = 1_790_740_802
    private static let tick = "2026-09-30 00:00:02"

    private nonisolated static func at(_ secondsAfterTick: TimeInterval) -> Date {
        Date(timeIntervalSince1970: tickEpoch + secondsAfterTick)
    }

    private nonisolated static func snapshot(at tick: String?) -> LiveCADSnapshot {
        LiveCADSnapshot(updatedFromDatabaseAt: tick, incidents: [])
    }

    // MARK: - Loading

    @Test("a successful load holds the snapshot and clears the failure")
    func loadHoldsTheSnapshot() async {
        let counter = FetchCounter()
        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                return Self.snapshot(at: Self.tick)
            },
            now: { Self.at(0) }
        )

        await feed.load()

        let fetches = await counter.count
        #expect(feed.snapshot?.updatedFromDatabaseAt == Self.tick)
        #expect(feed.failureMessage == nil)
        #expect(feed.isShowingStaleResult == false)
        #expect(fetches == 1)
    }

    @Test("a first fetch that fails says so, in place of the list")
    func firstFailureIsExplained() async {
        let feed = IncidentFeed(
            fetch: { throw URLError(.notConnectedToInternet) },
            now: { Self.at(0) }
        )

        await feed.load()

        #expect(feed.snapshot == nil)
        #expect(feed.failureMessage?.hasPrefix("The live feed could not be loaded.") == true)
    }

    /// The branch that matters most: emptying a screen a reader is using is worse than telling
    /// them it is old.
    @Test("a later fetch that fails keeps what is on screen and marks it stale")
    func laterFailureKeepsTheLastResult() async {
        let counter = FetchCounter()
        let good = Self.snapshot(at: Self.tick)

        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                if await counter.count == 1 {
                    return good
                }
                throw URLError(.timedOut)
            },
            now: { Self.at(0) }
        )

        await feed.load()
        await feed.load()

        #expect(feed.snapshot == good)
        #expect(feed.isShowingStaleResult == true)
        // Not a failure message: there is still something to read.
        #expect(feed.failureMessage == nil)
    }

    /// Reads the status from inside the fetch, which is the only moment `isRefreshing` is true
    /// — from outside, the line has already gone back to naming the data's age.
    @Test("a refresh in flight says so in the status, and stops when it is done")
    func statusSaysItIsChecking() async throws {
        let recorder = StatusRecorder()
        let box = FeedBox()

        box.feed = IncidentFeed(
            fetch: {
                if let text = await box.feed?.status.text {
                    await recorder.record(text)
                }
                return Self.snapshot(at: Self.tick)
            },
            now: { Self.at(0) }
        )

        let feed = try #require(box.feed)
        await feed.load()

        let seen = await recorder.seen
        #expect(seen.count == 1)
        #expect(seen.first?.hasSuffix("· checking…") == true)
        #expect(feed.status.text.hasSuffix("· checking…") == false)
    }

    // MARK: - The refresh gate

    /// The reason this type lives in the package: none of this was reachable from a test while
    /// it was private state inside a view.
    @Test("a refresh the City cannot have answered is skipped, and does not fetch")
    func skipsWhenTheCityCannotHaveRepublished() async {
        let counter = FetchCounter()
        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                return Self.snapshot(at: Self.tick)
            },
            // Four minutes after the tick. The City republishes on five-minute boundaries, so
            // there is provably nothing newer to ask for.
            now: { Self.at(240) }
        )

        await feed.load()
        let outcome = await feed.refresh()
        let fetches = await counter.count

        #expect(outcome == .skipped)
        #expect(fetches == 1, "a skipped refresh must not touch the network")
    }

    @Test("a refresh is allowed once the City could have republished")
    func refreshesAfterTheBoundary() async {
        let counter = FetchCounter()
        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                return Self.snapshot(at: Self.tick)
            },
            now: { Self.at(301) }
        )

        await feed.load()
        let outcome = await feed.refresh()
        let fetches = await counter.count

        #expect(outcome == .refreshed)
        #expect(fetches == 2)
    }

    /// The gate fails open. A value we cannot read must never quietly block a refresh.
    @Test("a refresh is allowed when there is nothing to compare against")
    func refreshesWithNoSnapshot() async {
        let counter = FetchCounter()
        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                return Self.snapshot(at: Self.tick)
            },
            now: { Self.at(0) }
        )

        let outcome = await feed.refresh()
        let fetches = await counter.count

        #expect(outcome == .refreshed)
        #expect(fetches == 1)
    }

    @Test("a refresh is allowed when the tick cannot be read")
    func refreshesOnAnUnreadableTick() async {
        let counter = FetchCounter()
        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                return Self.snapshot(at: "not a timestamp")
            },
            now: { Self.at(0) }
        )

        await feed.load()
        let outcome = await feed.refresh()
        let fetches = await counter.count

        #expect(outcome == .refreshed)
        #expect(fetches == 2)
    }

    // MARK: - What the line says

    @Test("the status names the age of the data, not the age of the request")
    func statusNamesTheDataAge() async {
        let feed = IncidentFeed(
            fetch: { Self.snapshot(at: Self.tick) },
            now: { Self.at(0) }
        )

        await feed.load()

        #expect(feed.status.text == "City data as of \(Self.tick)")
        #expect(feed.status.isStale == false)
    }

    @Test("the status warns when what is on screen is the last good result")
    func statusWarnsWhenStale() async {
        let counter = FetchCounter()
        let feed = IncidentFeed(
            fetch: {
                await counter.record()
                if await counter.count == 1 {
                    return Self.snapshot(at: Self.tick)
                }
                throw URLError(.timedOut)
            },
            now: { Self.at(0) }
        )

        await feed.load()
        await feed.load()

        #expect(feed.status.text == "City data as of \(Self.tick) · showing the last result")
        #expect(feed.status.isStale == true)
    }

    @Test("the skipped-refresh sentence names the tick it compared against")
    func nothingNewerNamesTheTick() async {
        let feed = IncidentFeed(
            fetch: { Self.snapshot(at: Self.tick) },
            now: { Self.at(240) }
        )

        await feed.load()

        #expect(feed.nothingNewerMessage == "Nothing newer than \(Self.tick).")
    }

    @Test("the skipped-refresh sentence copes with never having loaded")
    func nothingNewerWithoutASnapshot() {
        let feed = IncidentFeed(fetch: { Self.snapshot(at: Self.tick) })

        #expect(feed.nothingNewerMessage == "Nothing newer than an unknown time.")
    }
}
