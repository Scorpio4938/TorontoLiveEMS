import Foundation
import Testing
import TorontoLiveEMSKit

@Suite("Dispatch time formatting")
struct DispatchTimestampTests {

    /// A fixed zone, so an assertion about an instant does not depend on the machine it runs on.
    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    @Test("reduces a published timestamp to a clock time")
    func clockTime() {
        #expect(DispatchTimestamp.clockTime("2026-09-29T18:24:39") == "6:24 PM")
    }

    @Test("adds the date when there is room for it")
    func dateAndTime() {
        #expect(DispatchTimestamp.dateAndTime("2026-09-29T18:24:39") == "Sep 29, 6:24 PM")
    }

    @Test("handles midnight and noon, which are the easy ones to get wrong")
    func midnightAndNoon() {
        #expect(DispatchTimestamp.clockTime("2026-09-29T00:05:00") == "12:05 AM")
        #expect(DispatchTimestamp.clockTime("2026-09-29T12:00:00") == "12:00 PM")
        #expect(DispatchTimestamp.clockTime("2026-09-29T23:59:59") == "11:59 PM")
    }

    @Test("pads the minute but not the hour")
    func padding() {
        #expect(DispatchTimestamp.clockTime("2026-09-29T09:07:00") == "9:07 AM")
    }

    @Test("drops a leading zero from the day")
    func dayPadding() {
        #expect(DispatchTimestamp.dateAndTime("2026-01-05T08:00:00") == "Jan 5, 8:00 AM")
    }

    @Test("returns anything of an unexpected shape unchanged")
    func unknownShapeIsPassedThrough() {
        // An upstream format change should degrade to the raw value, not to a wrong one.
        #expect(DispatchTimestamp.clockTime("not a timestamp") == "not a timestamp")
        #expect(DispatchTimestamp.dateAndTime("") == "")
        #expect(DispatchTimestamp.clockTime("2026-09-29") == "2026-09-29")
        #expect(DispatchTimestamp.clockTime("2026-13-29T18:24:39") == "2026-13-29T18:24:39")
        #expect(DispatchTimestamp.clockTime("2026-09-29T25:00:00") == "2026-09-29T25:00:00")
        #expect(
            DispatchTimestamp.clockTime("nonsense", format: .twentyFourHour) == "nonsense"
        )
    }

    @Test("renders the time on the 24-hour clock when the reader asks for it")
    func twentyFourHour() {
        // The hour is padded, which is what the 24-hour clock means.
        #expect(
            DispatchTimestamp.clockTime("2026-09-29T18:24:39", format: .twentyFourHour)
                == "18:24"
        )
        #expect(
            DispatchTimestamp.clockTime("2026-09-29T09:07:00", format: .twentyFourHour)
                == "09:07"
        )
        #expect(
            DispatchTimestamp.clockTime("2026-09-29T00:05:00", format: .twentyFourHour)
                == "00:05"
        )
        #expect(
            DispatchTimestamp.clockTime("2026-09-29T12:00:00", format: .twentyFourHour)
                == "12:00"
        )
        #expect(
            DispatchTimestamp.clockTime("2026-09-29T23:59:59", format: .twentyFourHour)
                == "23:59"
        )
    }

    @Test("twelve-hour is the default, because it is what the City publishes")
    func twelveHourIsTheDefault() {
        #expect(
            DispatchTimestamp.clockTime("2026-09-29T18:24:39")
                == DispatchTimestamp.clockTime("2026-09-29T18:24:39", format: .twelveHour)
        )
    }

    // MARK: - The Service's own clock

    @Test("writes an instant in the City's shape, on the City's clock")
    func publishedStampUsesTheCitysShape() {
        // 16:54:19 UTC is 12:54:19 in Toronto in October. Pinned rather than taken from the device: a
        // reader in London and a reader in Vancouver must not disagree about when a Toronto service
        // last wrote, and the line beside this one quotes a Toronto wall clock.
        let instant = Date(timeIntervalSince1970: 1_791_219_259)

        #expect(DispatchTimestamp.publishedStamp(instant) == "2026-10-05 12:54:19")
        #expect(
            DispatchTimestamp.publishedStamp(instant, calendar: Self.utc) == "2026-10-05 16:54:19"
        )
    }

    @Test("follows Toronto's own daylight saving rather than a fixed offset")
    func publishedStampFollowsTheZone() {
        // A fixed -4 would be wrong for half the year. Asserted rather than assumed: a named zone knows
        // the rules and an offset does not.
        let winter = Date(timeIntervalSince1970: 1_767_225_600)  // 2026-01-01T00:00:00Z
        let summer = Date(timeIntervalSince1970: 1_782_950_400)  // 2026-07-02T00:00:00Z

        #expect(DispatchTimestamp.publishedStamp(winter) == "2025-12-31 19:00:00")
        // Still the first of July in Toronto, which is the point of asking the zone rather than the UTC
        // date: this instant is the second of July in UTC.
        #expect(DispatchTimestamp.publishedStamp(summer) == "2026-07-01 20:00:00")
    }
}
