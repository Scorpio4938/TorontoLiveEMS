import Foundation
import Testing

import TorontoLiveEMSKit

/// The generated facility file: the 16 divisions with a published address, and the three without.
@Suite("Police facilities")
struct PoliceFacilitiesTests {

    private var facilities: PoliceFacilities { PoliceFacilities.bundled }
    private var divisions: PoliceDivisions { PoliceDivisions.bundled }

    @Test("the bundled file loads with the 16 division facilities")
    func theFileLoads() {
        #expect(facilities.count == 16)
        #expect(facilities.facilities.count == 16)
        #expect(!facilities.source.isEmpty)
        #expect(!facilities.licence.isEmpty)
        #expect(!facilities.retrieved.isEmpty)
    }

    @Test("every facility belongs to a published division")
    func facilitiesBelongToDivisions() {
        for facility in facilities.facilities {
            #expect(divisions.division(forPublished: facility.division)?.number == facility.division)
        }
    }

    @Test("the feed's D14 and the City's 14 find the same facility")
    func d14And14AreOneFacility() throws {
        let fromFeed = try #require(facilities.facility(forPublished: "D14"))
        let fromCity = try #require(facilities.facility(forPublished: "14"))

        #expect(fromFeed == fromCity)
        #expect(fromFeed.address == "350 Dovercourt Road")
        #expect(fromFeed.postalCode == "M6J 3E3")
        #expect(abs(fromFeed.coordinate.latitude - 43.651305) < 0.00001)
        #expect(abs(fromFeed.coordinate.longitude - -79.425981) < 0.00001)
    }

    @Test("a division with no facility record has no facility, not a blank one")
    func absentFacilityIsNil() {
        // 00, 54 and 58 are published divisions with no facility row.
        #expect(facilities.facility(forPublished: "00") == nil)
        #expect(facilities.facility(forPublished: "54") == nil)
        #expect(facilities.facility(forPublished: "58") == nil)
        #expect(facilities.facility(forPublished: "D00") == nil)
        #expect(facilities.facility(forPublished: "D99") == nil)
    }

    @Test("the source, licence and retrieval date are recorded")
    func provenanceIsRecorded() {
        #expect(facilities.source.contains("toronto.ca"))
        #expect(facilities.source.contains("police-facility-locations"))
        #expect(facilities.licence.contains("Open Government Licence"))
        #expect(facilities.licence.contains("Toronto"))
        #expect(facilities.retrieved.count == 10)
    }

    @Test("something that is not the file is refused")
    func refusesRubbish() {
        #expect(throws: (any Error).self) {
            try PoliceFacilities(data: Data("not json".utf8))
        }
    }

    @Test("two rows for one division are refused")
    func refusesDuplicateDivision() {
        let document = """
            {"source":"s","licence":"l","retrieved":"2026-10-29","facilities":[
              {"division":"14","address":"a","postalCode":"M6J 3E3",
               "coordinate":{"latitude":43.65,"longitude":-79.42}},
              {"division":"D14","address":"b","postalCode":"M6J 3E3",
               "coordinate":{"latitude":43.65,"longitude":-79.42}}
            ]}
            """

        #expect(throws: PoliceFacilitiesError.duplicateDivision("14")) {
            try PoliceFacilities(data: Data(document.utf8))
        }
    }
}
