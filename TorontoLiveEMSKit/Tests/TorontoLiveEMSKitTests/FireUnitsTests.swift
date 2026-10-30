import Foundation
import Testing

import TorontoLiveEMSKit

/// The generated units file, and the two rules that decide what a code means.
@Suite("Fire units")
struct FireUnitsTests {

    private var units: FireUnits { FireUnits.bundled }
    private var stations: FireStations { FireStations.bundled }

    @Test("the bundled roster loads")
    func theFileLoads() {
        #expect(units.count > 100, "the active roster, not one dispatch capture")
        #expect(units.units.count == units.count)
        #expect(units.units.map(\.code) == units.units.map(\.code).sorted())
        #expect(!units.source.isEmpty)
        #expect(!units.licence.isEmpty)
        #expect(!units.retrieved.isEmpty)
        #expect(!units.capturedAt.isEmpty)
    }

    @Test("the file's names and stations are the rules' answers")
    func fileMatchesTheRules() {
        for unit in units.units {
            let derived = FireUnit(code: unit.code, stations: stations)
            #expect(
                unit.name == derived.name,
                "\(unit.code) is named \(String(describing: unit.name)) in the file"
            )
            #expect(
                unit.station == derived.station,
                "\(unit.code) is at \(String(describing: unit.station)) in the file"
            )
        }
    }

    @Test("a code whose digits are a station number is at that station")
    func stationNumberedCodeResolves() {
        let pumper = FireUnit(code: "P244", stations: stations)

        #expect(pumper.name == "Pumper")
        #expect(pumper.station == 244)
    }

    @Test("a code whose digits are not a station number belongs nowhere")
    func chiefCarBelongsToNoStation() {
        // `C23` is a Chief's car. Its digits are 23, and 23 is not one of the 84 station numbers,
        // so it is attached to no station — not "Station 23".
        let chief = FireUnit(code: "C23", stations: stations)

        #expect(chief.name == "Chief")
        #expect(chief.station == nil)
    }

    @Test("the longest matching legend entry names the unit")
    func longestLegendEntryWins() {
        // Without longest-first matching `CMD` would be a Chief and `PL231` a Pumper.
        #expect(FireUnit(code: "CMD", stations: stations).name == "Command Vehicle")
        #expect(FireUnit(code: "CMD1", stations: stations).name == "Command Vehicle")
        #expect(FireUnit(code: "C23", stations: stations).name == "Chief")
        #expect(FireUnit(code: "PL231", stations: stations).name == "Platform")
    }

    @Test("a code the legend does not name keeps its code and no name")
    func unnamedCodeStaysUnnamed() {
        // `L` is dispatched by the City but is not in the legend on the City's own page. An
        // unnamed code is shown as its code rather than guessed at.
        let ladder = FireUnit(code: "L312", stations: stations)

        #expect(ladder.name == nil)
        #expect(ladder.station == 312)
    }

    @Test("every station in the file is a published station number")
    func stationsInTheFileAreReal() {
        for unit in units.units {
            if let station = unit.station {
                #expect(
                    stations.station(number: station) != nil,
                    "\(unit.code) claims Station \(station), which is not in the station file"
                )
                #expect(unit.code.hasSuffix(String(station)))
            } else if let digits = DispatchedUnit(code: unit.code).station,
                let number = Int(digits)
            {
                // No station is the right answer only when those digits are not a station number.
                #expect(stations.station(number: number) == nil)
            }
        }
    }

    @Test("the roster holds both a station-numbered code and one with no station")
    func rosterExercisesBothAnswers() {
        #expect(units.units.contains { $0.station != nil })
        #expect(units.units.contains { $0.station == nil })
    }

    @Test("the source, licence, retrieval date and roster moment are recorded")
    func provenanceIsRecorded() {
        #expect(units.source.contains("fire.fandom.com"))
        #expect(units.licence.contains("CC BY-SA"))
        #expect(units.retrieved.count == 10)
        #expect(units.retrieved.split(separator: "-").count == 3)
        #expect(units.capturedAt.count == 19, "the roster's retrieval timestamp")
    }

    @Test("a roster code is found by its code")
    func findsARosterUnit() throws {
        let first = try #require(units.units.first)
        #expect(units.unit(code: first.code) == first)
        #expect(units.unit(code: " \(first.code) ") == first)
    }

    @Test("the units at a station are the ones the catalogue places there")
    func unitsAtAStation() {
        // Station 331 has a pumper, a ladder and a squad.
        let at331 = units.units(at: 331)
        #expect(at331.map(\.code) == ["L331", "P331", "S331"])
        #expect(at331.allSatisfy { $0.station == 331 })

        // A station the roster knows no unit for is an empty list, not an error.
        #expect(units.units(at: 999).isEmpty)

        // And every station the file does place a unit at really has it.
        for unit in units.units {
            guard let station = unit.station else { continue }
            #expect(units.units(at: station).contains(unit))
        }
    }

    @Test("a unit the roster did not hold is nil")
    func unknownUnitIsNil() {
        #expect(units.unit(code: "ZZZ999") == nil)
    }

    @Test("something that is not the file is refused")
    func refusesRubbish() {
        #expect(throws: (any Error).self) {
            try FireUnits(data: Data("not json".utf8))
        }
    }

    @Test("two rows for one code are refused")
    func refusesDuplicateUnit() {
        let document = """
            {"source":"s","licence":"l","retrieved":"2026-10-29",
             "capturedAt":"2026-10-29 16:40:01","units":[
              {"code":"P244","name":"Pumper","station":244},
              {"code":"P244","name":"Pumper","station":244}
            ]}
            """

        #expect(throws: FireUnitsError.duplicateUnit("P244")) {
            try FireUnits(data: Data(document.utf8))
        }
    }
}
