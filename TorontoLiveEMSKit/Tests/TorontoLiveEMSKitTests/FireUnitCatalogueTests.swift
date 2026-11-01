import Testing
import TorontoLiveEMSKit

/// The catalogue rules: how rows are grouped, how names are decided, and what "dispatched now"
/// means.
///
/// The bundled roster contains `C23` and `CMD10`, so the `C`/`CMD` pair is real in the data. The
/// grouping test builds the pair through the same `FireUnit` initialiser the import uses, so it
/// tests the rule rather than depending on the roster.
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

    @Test("units are grouped by apparatus type, not the first letter")
    func groupsByApparatusType() {
        let units = [
            FireUnit(code: "P244", stations: stations),
            FireUnit(code: "A231", stations: stations),
            FireUnit(code: "R346", stations: stations),
            FireUnit(code: "C23", stations: stations),
            FireUnit(code: "CMD1", stations: stations),
            FireUnit(code: "HR332", stations: stations),
            FireUnit(code: "HZ323", stations: stations),
            FireUnit(code: "L331", stations: stations),
        ]

        let groups = FireUnits.groups(of: units)

        #expect(groups.map(\.title) == [
            "Aerial", "Chief", "Command Vehicle", "HazMat", "Highrise", "Ladder", "Pumper",
            "Rescue",
        ])
        #expect(groups.first { $0.title == "HazMat" }?.units.map(\.code) == ["HZ323"])
        #expect(groups.first { $0.title == "Highrise" }?.units.map(\.code) == ["HR332"])
        #expect(groups.first { $0.title == "Ladder" }?.units.map(\.code) == ["L331"])
        #expect(groups.first { $0.title == "Pumper" }?.units.map(\.code) == ["P244"])
        #expect(groups.first { $0.title == "Rescue" }?.units.map(\.code) == ["R346"])
    }

    @Test("C23 and CMD… are different apparatus types")
    func chiefAndCommandAreDifferentTypes() throws {
        let c23 = FireUnit(code: "C23", stations: stations)
        let command = FireUnit(code: "CMD1", stations: stations)
        let groups = FireUnits.groups(of: [command, c23])

        #expect(groups.map(\.title) == ["Chief", "Command Vehicle"])

        let chief = try #require(groups.first { $0.title == "Chief" })
        #expect(chief.units.map(\.code) == ["C23"])
        #expect(chief.units.first?.name == "Chief")

        let commandGroup = try #require(groups.first { $0.title == "Command Vehicle" })
        #expect(commandGroup.units.map(\.code) == ["CMD1"])
        #expect(commandGroup.units.first?.name == "Command Vehicle")
    }

    @Test("a type the legend does not name falls back to the code prefix")
    func unnamedTypeFallsBackToPrefix() throws {
        let unknown = FireUnit(code: "X331", stations: stations)
        let group = try #require(FireUnits.groups(of: [unknown]).first)

        #expect(unknown.name == nil)
        #expect(group.title == "X")
    }

    @Test("a unit with no station is still catalogued, and shows no station")
    func stationlessUnit() {
        let chief = FireUnit(code: "C23", stations: stations)

        #expect(chief.station == nil)
        #expect(FireUnits.groups(of: [chief]).first?.units.first?.station == nil)
    }

    @Test("the bundled catalogue is grouped by apparatus type, in title order")
    func bundledGroups() {
        let groups = FireUnits.bundled.groups

        #expect(!groups.isEmpty)
        #expect(groups.map(\.title) == groups.map(\.title).sorted())
        #expect(groups.flatMap { $0.units }.count == FireUnits.bundled.count)

        // The group is the legend name, falling back to the first character only for a code the
        // legend does not name. Within a group the rows are in code order.
        for group in groups {
            #expect(group.units.map(\.code) == group.units.map(\.code).sorted())
            for unit in group.units {
                #expect(group.title == (unit.name ?? String(unit.code.prefix(1)).uppercased()))
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
