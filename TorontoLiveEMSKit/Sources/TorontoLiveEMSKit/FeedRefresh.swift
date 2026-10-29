import Foundation

/// Whether the City can have republished since the tick we last saw.
///
/// The feed is a five-minute snapshot, and `update_from_db_time` always lands on a
/// five-minute boundary — sampled ticks are `23:55:02`, `00:00:02`, never `23:57`. Between
/// two boundaries there is provably nothing new to fetch, so asking anyway is a request
/// whose answer we already know. See `docs/design-decisions.md`.
public enum FeedRefresh {

    /// How often the City republishes.
    ///
    /// Observed rather than documented: it is the interval the published ticks actually
    /// fall on.
    public static let interval: TimeInterval = 5 * 60

    /// Whether a refresh could return something newer than `tick`.
    ///
    /// Answers `true` whenever it cannot tell — no tick yet, or a timestamp of an
    /// unexpected shape — so a value we fail to read never quietly blocks a refresh.
    public static func mayHaveRefreshed(
        since tick: String?,
        now: Date = Date()
    ) -> Bool {
        guard let tick, let published = dateFromTorontoWallClock(tick) else {
            return true
        }
        return now >= published.addingTimeInterval(interval)
    }

    /// Reads `2026-09-30 00:00:02` as Toronto local time.
    ///
    /// Toronto specifically, because that is whose clock the feed publishes on. The zone is
    /// used for this comparison only and never for display: the app still shows the City's
    /// timestamp exactly as it was sent, so nothing on screen is shifted by the reader's
    /// own clock.
    private static func dateFromTorontoWallClock(_ tick: String) -> Date? {
        let halves = tick.split(separator: " ")
        guard halves.count == 2 else {
            return nil
        }

        let date = halves[0].split(separator: "-")
        let time = halves[1].split(separator: ":")

        guard date.count == 3,
              time.count >= 2,
              let year = Int(date[0]),
              let month = Int(date[1]),
              let day = Int(date[2]),
              let hour = Int(time[0]),
              let minute = Int(time[1]),
              let zone = TimeZone(identifier: "America/Toronto")
        else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = time.count > 2 ? Int(time[2]) : 0
        components.timeZone = zone

        return Calendar(identifier: .gregorian).date(from: components)
    }
}
