/// How a dispatch time should be rendered for reading.
import Foundation

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

    /// The clock time of an instant, in the reader's own zone.
    ///
    /// **The fire feed publishes a wall-clock string and it is shown as published** — see the note at
    /// the top of this type, which is why that path never goes near a date formatter. A police call
    /// publishes an *instant* instead, and an instant has no clock until somebody chooses a zone.
    /// The reader's own is the only honest choice.
    ///
    /// Done through `Calendar` rather than `DateFormatter`, for the reason the rest of this type is
    /// done by hand: the parts are what the app wants, and a formatter would put the format in a
    /// locale's hands instead of in the reader's setting. The calendar is a parameter so that a test
    /// can pin a zone rather than depend on the machine it runs on.
    public static func clockTime(
        _ instant: Date,
        format: DispatchTimeFormat = .twelveHour,
        calendar: Calendar = .current
    ) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: instant)
        // Unreachable for a real `Date` and a real `Calendar`, and marked rather than guessed at: a
        // caller cannot tell the difference between a component that failed and midnight.
        guard let hour = parts.hour, let minute = parts.minute else { return NotProvided.mark }

        switch format {
        case .twentyFourHour:
            return String(format: "%02d:%02d", hour, minute)
        case .twelveHour:
            let display = hour % 12 == 0 ? 12 : hour % 12
            return String(format: "%d:%02d %@", display, minute, hour < 12 ? "AM" : "PM")
        }
    }

    /// The publisher's clock, which is the one the City's own line is written on.
    ///
    /// A fixed zone rather than the reader's, and named rather than inferred: one instant is a
    /// different wall clock in every zone, and the clock this data is written on is Toronto's. The
    /// fallback is GMT rather than `.current` so that the answer never depends on the device — a
    /// rendering that quietly followed the reader would make the tests depend on the machine they run
    /// on, which is the thing the `calendar:` parameters in this type exist to prevent.
    public static var torontoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto") ?? .gmt
        return calendar
    }

    /// An instant in the shape the City publishes its own refresh tick in: `2026-10-05 14:00:02`.
    ///
    /// **Toronto's clock, not the reader's.** The fire feed's status line quotes the City's string,
    /// which is Toronto wall-clock and unshifted by where the reader is; the police feed has an instant
    /// and no string, so it is rendered on the publisher's clock to match. Two lines a reader compares
    /// should be on one clock as well as in one shape.
    ///
    /// By hand rather than with a `DateFormatter`, for this type's usual reason and one more: a
    /// formatter would put the calendar in a locale's hands, and a reader whose device is set to a
    /// non-Gregorian calendar would see the Service's clock in a year it has never published.
    public static func publishedStamp(
        _ instant: Date,
        calendar: Calendar = torontoCalendar
    ) -> String {
        let parts = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: instant
        )
        // Unreachable for a real `Date` and a real `Calendar`, and marked rather than guessed at — the
        // same judgement the instant-based clock time above makes.
        guard let year = parts.year,
              let month = parts.month,
              let day = parts.day,
              let hour = parts.hour,
              let minute = parts.minute,
              let second = parts.second
        else {
            return NotProvided.mark
        }

        let date = "\(padded(year, to: 4))-\(padded(month, to: 2))-\(padded(day, to: 2))"
        let time = "\(padded(hour, to: 2)):\(padded(minute, to: 2)):\(padded(second, to: 2))"
        return "\(date) \(time)"
    }

    /// Padded by hand rather than with `String(format:)`, which is the judgement the published-string
    /// path in this type already records: an `Int` against `%d` is a width mismatch on a 64-bit
    /// platform, and it is the kind that produces a plausible wrong answer rather than a crash.
    private static func padded(_ value: Int, to width: Int) -> String {
        let text = String(value)
        return String(repeating: "0", count: max(0, width - text.count)) + text
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
