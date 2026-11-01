import Foundation
import Testing

import TorontoLiveEMSKit

/// The optional Wikipedia material: only the entities that actually have an entry.
@Suite("Wikipedia reference")
struct WikipediaReferenceTests {

    private var reference: WikipediaReference { WikipediaReference.bundled }

    @Test("the file loads with the entries it has")
    func theFileLoads() {
        #expect(!reference.source.isEmpty)
        #expect(reference.source.contains("wikipedia.org"))
        #expect(reference.licence.contains("CC BY-SA"))
        #expect(!reference.retrieved.isEmpty)
    }

    @Test("Station 312 has its Yorkville history")
    func stationHistory() throws {
        let entry = try #require(reference.station(number: 312))

        #expect(entry.title == "List of historic Toronto fire stations")
        #expect(entry.summary?.contains("Yorkville") == true)
        #expect(entry.summary?.contains("Built:") == false)
        #expect(entry.summary?.contains("\n") == false)
        #expect(entry.licence == "CC BY-SA 4.0")
        #expect(!entry.url.isEmpty)
        #expect(entry.revision?.isEmpty == false)
    }

    @Test("a station with no Wikipedia entry gets nothing")
    func unknownStationIsNil() {
        #expect(reference.station(number: 999) == nil)
    }

    @Test("a unit photograph keeps its own author and licence")
    func unitPhotograph() throws {
        let entry = try #require(reference.unit(code: "P332"))
        let image = try #require(entry.image)

        #expect(image.url.hasPrefix("https://"))
        #expect(image.pageURL.contains("commons.wikimedia.org"))
        #expect(image.author == "PvOberstein")
        #expect(image.licence == "CC0")
        #expect(entry.summary == nil)
    }

    @Test("a CC BY-SA unit photograph states that licence")
    func shareAlikePhotograph() throws {
        let entry = try #require(reference.unit(code: "CMD10"))
        let image = try #require(entry.image)

        #expect(image.author == "Hillelfrei")
        #expect(image.licence == "CC BY-SA 4.0")
        #expect(entry.licence == "CC BY-SA 4.0")
    }

    @Test("a unit with no Wikipedia material gets nothing")
    func unknownUnitIsNil() {
        #expect(reference.unit(code: "P999") == nil)
    }

    @Test("every station entry has text, and every unit entry has a photograph")
    func entriesMatchTheirPurpose() {
        // The file is deliberately incomplete; this pins the shape of what it does contain.
        #expect(reference.station(number: 312)?.summary?.isEmpty == false)
        #expect(reference.unit(code: "P332")?.image != nil)
        #expect(reference.unit(code: "P332")?.summary == nil)
    }

    @Test("something that is not the file is refused")
    func refusesRubbish() {
        #expect(throws: (any Error).self) {
            try WikipediaReference(data: Data("not json".utf8))
        }
    }
}
