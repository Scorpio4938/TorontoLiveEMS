import Testing
import TorontoLiveEMSKit

@Suite("Dispatch time formatting")
struct DispatchTimestampTests {

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
    }
}
