/// How a dispatch time should be rendered for reading.
public enum DispatchTimeFormat: String, CaseIterable, Sendable {

    /// `6:24 PM` — what the City's own page shows.
    case twelveHour

    /// `18:24`
    case twentyFourHour
}

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

    /// The time of day, in the requested format.
    ///
    /// Twelve-hour is the default because it is what the City publishes.
    public static func clockTime(
        _ published: String,
        format: DispatchTimeFormat = .twelveHour
    ) -> String {
        guard let parts = Parts(published) else {
            return published
        }

        switch format {
        case .twelveHour:
            return parts.twelveHour
        case .twentyFourHour:
            return parts.twentyFourHour
        }
    }

    /// `Sep 29, 6:24 PM`. Kept for a display with room for the date.
    public static func dateAndTime(_ published: String) -> String {
        guard let parts = Parts(published) else {
            return published
        }
        return "\(parts.month) \(parts.day), \(parts.twelveHour)"
    }

    private struct Parts {

        let month: String
        let day: String
        let hour24: Int
        let minute: String

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
                  let hour = Int(time[0]),
                  let minuteNumber = Int(time[1]),
                  (1...12).contains(monthNumber),
                  (1...31).contains(dayNumber),
                  (0...23).contains(hour),
                  (0...59).contains(minuteNumber)
            else {
                return nil
            }

            self.month = Self.monthNames[monthNumber - 1]
            self.day = String(dayNumber)
            self.hour24 = hour
            // Padded by hand rather than with String(format:), where an Int against a
            // `%d` format is a width mismatch on a 64-bit platform.
            self.minute = minuteNumber < 10 ? "0\(minuteNumber)" : String(minuteNumber)
        }

        /// `6:24 PM` — the hour unpadded, as the City shows it.
        var twelveHour: String {
            let hour = hour24 % 12 == 0 ? 12 : hour24 % 12
            let meridiem = hour24 < 12 ? "AM" : "PM"
            return "\(hour):\(minute) \(meridiem)"
        }

        /// `18:24` — the hour padded, which is what the 24-hour clock means.
        var twentyFourHour: String {
            let hour = hour24 < 10 ? "0\(hour24)" : String(hour24)
            return "\(hour):\(minute)"
        }

        private static let monthNames = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
        ]
    }
}
