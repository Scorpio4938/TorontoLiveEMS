import Foundation
import Testing

import TorontoLiveEMSKit

/// The generated division file, and the one thing that has to be normalised about it.
@Suite("Police divisions")
struct PoliceDivisionsTests {

    private var divisions: PoliceDivisions { PoliceDivisions.bundled }

    @Test("the bundled file loads with the 19 published divisions")
    func theFileLoads() {
        #expect(divisions.count == 19, "the published boundary file has 19 features")
        #expect(divisions.divisions.count == 19)
        #expect(divisions.divisions.map(\.number) == divisions.divisions.map(\.number).sorted())
        #expect(!divisions.source.isEmpty)
        #expect(!divisions.licence.isEmpty)
        #expect(!divisions.retrieved.isEmpty)
    }

    @Test("the feed's D14 and the City's 14 are one division")
    func d14NormalisesTo14() throws {
        let fromFeed = try #require(divisions.division(forPublished: "D14"))
        let fromCity = try #require(divisions.division(forPublished: "14"))

        #expect(fromFeed == fromCity)
        #expect(fromFeed.number == "14")
        #expect(fromFeed.feedCode == "D14")
    }

    @Test("a division the file does not know is nil, not a made-up one")
    func unknownDivisionIsNil() {
        #expect(divisions.division(forPublished: "D99") == nil)
        #expect(divisions.division(forPublished: "99") == nil)
        #expect(divisions.division(forPublished: "") == nil)
        #expect(divisions.division(forPublished: "D") == nil)
    }

    @Test("a division matches a published call in either spelling")
    func matchesBothSpellings() throws {
        let division = try #require(divisions.division(forPublished: "D14"))

        #expect(division.matches(published: "D14"))
        #expect(division.matches(published: "14"))
        #expect(division.matches(published: " d14 "))
        #expect(!division.matches(published: "D13"))
        #expect(!division.matches(published: "D99"))
    }

    @Test("normalising trims whitespace and ignores case")
    func normalisingIsForgiving() {
        #expect(divisions.division(forPublished: " d14 ")?.number == "14")
        #expect(divisions.division(forPublished: "D14")?.number == "14")
        #expect(divisions.division(forPublished: "14")?.number == "14")
    }

    @Test("every published division number is two digits")
    func numbersAreTwoDigits() {
        for division in divisions.divisions {
            #expect(division.number.count == 2, "\(division.number) is not two digits")
            #expect(division.number.allSatisfy(\.isNumber))
        }
        // The published file includes the division whose number leads with zero, and so does the
        // app. Dropping it would be tidying somebody else's data.
        #expect(divisions.divisions.contains { $0.number == "00" })
    }

    @Test("the source, licence and retrieval date are recorded")
    func provenanceIsRecorded() {
        #expect(divisions.source.contains("toronto.ca"))
        #expect(divisions.source.contains("police-boundaries"))
        #expect(divisions.licence.contains("Open Government Licence"))
        #expect(divisions.licence.contains("Toronto"))
        #expect(divisions.retrieved.count == 10)
        #expect(divisions.retrieved.split(separator: "-").count == 3)
    }

    @Test("something that is not the file is refused")
    func refusesRubbish() {
        #expect(throws: (any Error).self) {
            try PoliceDivisions(data: Data("not json".utf8))
        }
    }

    @Test("two spellings of one division are refused")
    func refusesDuplicateDivision() {
        let document = """
            {"source":"s","licence":"l","retrieved":"2026-10-29","divisions":[
              {"number":"14"},{"number":"D14"}
            ]}
            """

        // Normalisation happens on the way in, so these are two rows for one division rather than
        // two divisions. A file that holds both would let the app show both.
        #expect(throws: PoliceDivisionsError.duplicateDivision("14")) {
            try PoliceDivisions(data: Data(document.utf8))
        }
    }
}
