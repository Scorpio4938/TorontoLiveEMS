import Foundation
import Testing

import TorontoLiveEMSKit

/// The police calls: the source, the parser, and the columns they are shown in.
///
/// **The fixture is invented.** Its *shape* is the real service's — captured while researching this,
/// field for field — and its values are not, because real calls name real places and real events,
/// and a fixture is a thing that gets committed and read by strangers. The fire feed's captured
/// response is in this suite because a City press release is what it is; a police call about a
/// person is not, even when it is published.
@Suite("Police calls")
struct PoliceCallTests {

    /// One response in the shape the service sends, with the three cross-street forms in it: a
    /// published intersection, nothing at all, and the Service's dangling separator.
    private static let response = Data("""
    {"features":[
      {"attributes":{"OBJECTID":12,"OCCURRENCE_TIME":1791219259000,"DIVISION":"D14",
        "LATITUDE":43.66301980908665,"LONGITUDE":-79.42088902793036,
        "CALL_TYPE_CODE":"PERGU","CALL_TYPE":"PERSON WITH A GUN",
        "CROSS_STREETS":"CHRISTIE ST - BLOOR ST W"}},
      {"attributes":{"OBJECTID":11,"OCCURRENCE_TIME":1791219000000,"DIVISION":"D42",
        "LATITUDE":43.781056836166805,"LONGITUDE":-79.29810638446001,
        "CALL_TYPE_CODE":"UNKTR","CALL_TYPE":"UNKNOWN TROUBLE","CROSS_STREETS":""}},
      {"attributes":{"OBJECTID":10,"OCCURRENCE_TIME":1791218000000,"DIVISION":"D55",
        "LATITUDE":43.7,"LONGITUDE":-79.4,
        "CALL_TYPE_CODE":"ASSAULT","CALL_TYPE":"ASSAULT","CROSS_STREETS":"BONIS AVE - "}}
    ]}
    """.utf8)

    private static func calls() throws -> [PoliceCall] {
        try CallsForServiceParser.parse(response)
    }

    // MARK: - The parser

    @Test("reads every row, in the order the service returned them")
    func readsEveryRow() throws {
        let calls = try Self.calls()
        #expect(calls.count == 3)
        #expect(calls.map(\.objectID) == [12, 11, 10])
        #expect(calls.map(\.callType) == ["PERSON WITH A GUN", "UNKNOWN TROUBLE", "ASSAULT"])
    }

    @Test("turns published milliseconds into an instant, not into a second count")
    func readsTheTimeAsMilliseconds() throws {
        let call = try #require(try Self.calls().first)
        // The value in the fixture is 1791219259000. A parser that treated it as seconds would land
        // fifty thousand years out; one that forgot the division would land in 1970.
        #expect(call.occurrenceTime == Date(timeIntervalSince1970: 1_791_219_259))
    }

    @Test("keeps the published point rather than a geocoded one")
    func keepsThePublishedPoint() throws {
        let call = try #require(try Self.calls().first)
        #expect(call.latitude == 43.66301980908665)
        #expect(call.longitude == -79.42088902793036)
        #expect(call.division == "D14")
        #expect(call.callTypeCode == "PERGU")
    }

    @Test("a cross streets value with nothing in it is nothing")
    func emptyCrossStreetsIsNil() throws {
        let calls = try Self.calls()
        #expect(calls[1].crossStreets == nil)
    }

    @Test("a one-sided intersection is kept as published")
    func danglingSeparatorSurvives() throws {
        // `"BONIS AVE - "` has letters in it, so the "no letter and no digit" rule leaves it alone.
        // What to do with the Service's dangling separator is a display decision.
        let calls = try Self.calls()
        #expect(calls[2].crossStreets == "BONIS AVE - ")
    }

    @Test("refuses a response that is not the service's")
    func refusesWhatItCannotRead() {
        #expect(throws: CallsForServiceParserError.self) {
            try CallsForServiceParser.parse(Data("not json".utf8))
        }
        // A row missing a required field is refused rather than half-read, so a schema change is a
        // failure rather than a list with holes in it.
        #expect(throws: CallsForServiceParserError.self) {
            try CallsForServiceParser.parse(Data(#"{"features":[{"attributes":{"OBJECTID":1}}]}"#.utf8))
        }
    }

    // MARK: - The query

    @Test("asks with a TIMESTAMP literal, in UTC")
    func theTimeFilterIsALiteral() throws {
        // Both halves were measured against the live service: a bare millisecond number answers
        // "Invalid query parameters", and a literal is read as UTC. This test is the record of
        // that, so a future simplification to a number fails here instead of in the app.
        let now = Date(timeIntervalSince1970: 1_791_219_600)
        let url = try #require(CallsForServiceFeed.queryURL(now: now))
        let query = try #require(url.query)

        // `now` is 17:00:00 UTC and the window is four hours, so the filter asks from 13:00:00 —
        // checked by arithmetic rather than by writing down what the result ought to look like.
        #expect(query.contains("OCCURRENCE_TIME > TIMESTAMP '2026-10-05 13:00:00'"))
        #expect(!query.contains("OCCURRENCE_TIME > 1791219600"))
        #expect(query.contains("f=json"), "GeoJSON stringifies every attribute; its own JSON does not")
        #expect(query.contains("returnGeometry=false"), "the point is in the attributes")
        #expect(!query.contains("OCCURRENCE_TIME_AGOL"), "one copy of the time is enough")
    }

    @Test("the page a person can open is a real URL")
    func thePageURLIsUsable() throws {
        let url = try #require(CallsForServiceFeed.pageURL)
        #expect(url.scheme == "https")
        #expect(CallsForServiceFeed.licenceName.contains("Ontario"))
    }

    // MARK: - The columns

    @Test("four columns, in fire's rhythm: where, when, what, who")
    func theColumnSet() {
        #expect(CompactColumn<PoliceCall>.police.map(\.label) == [
            "Cross Streets",
            "Occurrence Time",
            "Call Type",
            "Division",
        ])
    }

    @Test("the card reads a different order from the table, as fire's does")
    func theCardOrder() {
        #expect(CompactColumn<PoliceCall>.policeCard.map(\.label) == [
            "Cross Streets",
            "Call Type",
            "Occurrence Time",
            "Division",
        ])
    }

    @Test("the clock column hears the reader's setting")
    func theClockColumnHonoursTheFormat() throws {
        // A pinned zone, so the expectation does not depend on where this runs.
        let call = try #require(try Self.calls().first)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try #require(TimeZone(secondsFromGMT: 0))

        #expect(
            DispatchTimestamp.clockTime(call.occurrenceTime, format: .twentyFourHour, calendar: utc)
                == "16:54"
        )
        #expect(
            DispatchTimestamp.clockTime(call.occurrenceTime, format: .twelveHour, calendar: utc)
                == "4:54 PM"
        )
        // And through the column itself, which is what the table draws.
        let cell = CompactColumn<PoliceCall>.occurrenceTime.cell(
            call,
            .twentyFourHour
        )
        #expect(cell.text?.contains(":") == true)
    }

    @Test("the first column shows the mark rather than nothing")
    func theFirstColumnIsNeverEmpty() throws {
        // The same judgement the fire table makes on its own first column: an empty cell at the
        // start of a row reads as a fault rather than as restraint.
        let calls = try Self.calls()
        let cell = CompactColumn<PoliceCall>.crossStreets.cell(calls[1], .twelveHour)
        #expect(cell.text == NotProvided.mark)
        #expect(!cell.isFallback, "there is no substitute here, so nothing is marked as one")
    }

    @Test("the note a screen quotes is the Service's own words")
    func theSourceNoteIsTheServicesOwnWords() {
        // Quoted rather than paraphrased, and short because short is all there was: the item and its
        // layer both leave `description` empty, so this sentence is the whole of what the Service
        // says about its own data in machine-readable form.
        #expect(!CallsForServiceFeed.sourceNote.isEmpty)
        #expect(CallsForServiceFeed.sourceNote.contains("prepared for public use"))
    }

    @Test("the cadence note and the window say the same four hours")
    func theNoteAgreesWithTheWindow() {
        // Tied together on purpose: the sentence on screen and the interval the query asks for are
        // the same claim, and a change to one that leaves the other behind is a lie with a test
        // missing. The second assertion is the one that matters — ADR-0006 records that the Service's
        // refresh rate could not be verified, so the app must not claim one.
        #expect(CallsForServiceFeed.window == 4 * 60 * 60)
        #expect(CallsForServiceFeed.cadenceNote.contains("four hours"))
        #expect(CallsForServiceFeed.cadenceNote.contains("no cadence"))
    }
}
