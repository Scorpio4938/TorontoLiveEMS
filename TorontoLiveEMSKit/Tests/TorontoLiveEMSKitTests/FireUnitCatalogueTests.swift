import Foundation
import Testing
import TorontoLiveEMSKit

/// The catalogue rules: how rows are grouped, how names are decided, and what "dispatched now"
/// means.
///
/// The bundled capture does not happen to contain the letter-collision pair the issue names, so the
/// grouping test builds `C23` and `CMD1` through the same `FireUnit` initialiser the import uses.
/// That is the rule under test, not a second copy of it.
@Suite("Fire unit catalogue")
struct FireUnitCatalogueTests {

    private var stations: FireStations { FireStations.bundled }

    private func incident(_ number: String, units: String?) -> Incident {
        Incident(
            incidentNumber: number,
            primeStreet: "M6K",
            crossStreets: nil,
            dispatchTime: "2026-10-29T16:30:00",
            incidentType: "MEDICAL",
            alarmLevel: "0",
            area: "426",
            dispatchedUnits: units
        )
    }

    @Test("units are grouped by the leading letter of the code")
    func groupsByLeadingLetter() {
        let units = [
            FireUnit(code: "P244", stations: stations),
            FireUnit(code: "A231", stations: stations),
            FireUnit(code: "C23", stations: stations),
            FireUnit(code: "CMD1", stations: stations),
            FireUnit(code: "HR332", stations: stations),
            FireUnit(code: "HZ323", stations: stations),
        ]

        let groups = FireUnits.groups(of: units)

        #expect(groups.map(\.letter) == ["A", "C", "H", "P"])
        #expect(groups.first { $0.letter == "H" }?.units.map(\.code) == ["HR332", "HZ323"])
        #expect(groups.first { $0.letter == "P" }?.units.map(\.code) == ["P244"])
    }

    @Test("C23 and CMD… share the C group and are named differently")
    func letterCollisionDoesNotDecideTheName() throws {
        let c23 = FireUnit(code: "C23", stations: stations)
        let command = FireUnit(code: "CMD1", stations: stations)
        let group = try #require(
            FireUnits.groups(of: [command, c23]).first { $0.letter == "C" }
        )

        #expect(group.units.map(\.code) == ["C23", "CMD1"])
        #expect(group.units.first?.name == "Chief")
        #expect(group.units.last?.name == "Command Vehicle")
    }

    @Test("a unit with no station is still catalogued, and shows no station")
    func stationlessUnit() {
        let chief = FireUnit(code: "C23", stations: stations)

        #expect(chief.station == nil)
        #expect(FireUnits.groups(of: [chief]).first?.units.first?.station == nil)
    }

    @Test("the bundled catalogue is grouped by letter, in order")
    func bundledGroups() {
        let groups = FireUnits.bundled.groups

        #expect(!groups.isEmpty)
        #expect(groups.map(\.letter) == groups.map(\.letter).sorted())
        #expect(groups.flatMap(\.units).count == FireUnits.bundled.count)

        // The group letter is the code's first character, never a reading of the name.
        for group in groups {
            for unit in group.units {
                #expect(String(unit.code.prefix(1)).uppercased() == group.letter)
            }
        }
    }

    @Test("an incident's roster names a unit by exact code")
    func liveRosterMatching() {
        let pumper = FireUnit(code: "P244", stations: stations)
        let incident = incident("F1", units: "P244, R244")

        #expect(pumper.isDispatched(to: incident))
        #expect(!FireUnit(code: "P24", stations: stations).isDispatched(to: incident))
        #expect(!FireUnit(code: "C23", stations: stations).isDispatched(to: incident))
    }

    @Test("an incident with no roster names no unit")
    func absentRosterMatchesNothing() {
        let pumper = FireUnit(code: "P244", stations: stations)

        #expect(!pumper.isDispatched(to: incident("F1", units: nil)))
        #expect(!pumper.isDispatched(to: incident("F2", units: "")))
    }
}
