import Foundation

/// Formats the feed's dispatch timestamp for people.
///
/// The feed publishes local Toronto wall-clock time with no UTC offset —
/// `2026-09-29T18:24:39`. Reading the components straight out of the string means the
/// time a reader sees is the time the City published. Handing it to a date formatter
/// would mean choosing a time zone on the City's behalf, and would silently shift every
/// value for anyone whose device is set elsewhere.
///
/// Anything that does not match the published shape comes back unchanged, so an
/// upstream format change degrades to the raw value rather than to a wrong one.
public enum DispatchTimestamp {

    /// `6:24 PM`. For the compact table, where an active incident is almost always
    /// from today and the date would be a near-constant column.
    public static func clockTime(_ published: String) -> String {
        guard let parts = Parts(published) else {
            return published
        }
        return "\(parts.hour):\(parts.minute) \(parts.meridiem)"
    }

    /// `Sep 29, 6:24 PM`. For the detail view, where there is room for the date.
    public static func dateAndTime(_ published: String) -> String {
        guard let parts = Parts(published) else {
            return published
        }
        return "\(parts.month) \(parts.day), \(parts.hour):\(parts.minute) \(parts.meridiem)"
    }

    private struct Parts {

        let month: String
        let day: String
        let hour: String
        let minute: String
        let meridiem: String

        init?(_ published: String) {
            let halves = published.split(separator: "T")
            guard halves.count == 2 else {
                return nil
            }

            let date = halves[0].split(separator: "-")
            let time = halves[1].split(separator: ":")

            guard date.count == 3,
                  time.count >= 2,
                  let monthNumber = Int(date[1]),
                  let dayNumber = Int(date[2]),
                  let hour24 = Int(time[0]),
                  let minuteNumber = Int(time[1]),
                  (1...12).contains(monthNumber),
                  (1...31).contains(dayNumber),
                  (0...23).contains(hour24),
                  (0...59).contains(minuteNumber)
            else {
                return nil
            }

            self.month = Self.monthNames[monthNumber - 1]
            self.day = String(dayNumber)
            self.minute = String(format: "%02d", minuteNumber)
            self.hour = String(hour24 % 12 == 0 ? 12 : hour24 % 12)
            self.meridiem = hour24 < 12 ? "AM" : "PM"
        }

        private static let monthNames = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
        ]
    }
}
