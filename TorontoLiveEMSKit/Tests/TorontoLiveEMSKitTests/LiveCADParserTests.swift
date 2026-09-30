import Foundation
import Testing
import TorontoLiveEMSKit

@Suite("Live CAD parsing")
struct LiveCADParserTests {

    // MARK: - The captured snapshot

    @Test("reads the feed's own last-updated time")
    func readsFeedTimestamp() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)

        #expect(snapshot.updatedFromDatabaseAt == "2026-09-29 20:00:01")
    }

    @Test("reads every active incident")
    func readsEveryIncident() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)

        #expect(snapshot.incidents.count == 13)
    }

    @Test("keeps the order the feed published")
    func keepsPublishedOrder() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)

        #expect(snapshot.incidents.first?.incidentNumber == "F26154815")
        #expect(snapshot.incidents.last?.incidentNumber == "F26154880")
        #expect(snapshot.incidents.map(\.dispatchTime) == snapshot.incidents.map(\.dispatchTime).sorted())
    }

    @Test("captures all eight published fields")
    func capturesEveryField() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)
        let incident = try #require(snapshot.incidents.first)

        #expect(incident.incidentNumber == "F26154815")
        #expect(incident.primeStreet == "M6K")
        #expect(incident.crossStreets == nil)
        #expect(incident.dispatchTime == "2026-09-29T18:24:39")
        #expect(incident.incidentType == "MEDICAL")
        #expect(incident.alarmLevel == "0")
        #expect(incident.area == "426")
        #expect(incident.dispatchedUnits == "R346")
    }

    @Test("identifies an incident by its incident number")
    func identifiesById() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)
        let incident = try #require(snapshot.incidents.first)

        #expect(incident.id == incident.incidentNumber)
    }

    // MARK: - "Not published", expressed three ways

    @Test("treats an XML-escaped space in Prime Street as not published")
    func escapedSpacePrimeStreet() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)
        let incident = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154841" }
        )

        // The feed sends <prime_street>&#x20;</prime_street> for this incident.
        #expect(incident.primeStreet == nil)
        #expect(incident.crossStreets == "WOODBINE AVE / KINGSTON RD")
    }

    @Test("treats an empty element as not published")
    func emptyElement() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)
        let incident = try #require(snapshot.incidents.first)

        // <cross_streets/> — element present, no text.
        #expect(incident.crossStreets == nil)
    }

    @Test("treats a missing element as not published")
    func missingElement() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.unitsElementAbsentData)
        let incident = try #require(snapshot.incidents.first)

        // This payload has no <units_disp> element at all.
        #expect(incident.dispatchedUnits == nil)
        #expect(incident.incidentNumber == "F1")
        #expect(incident.primeStreet == "M1A")
    }

    // MARK: - Values that must survive verbatim

    @Test("keeps a multi-apparatus roster as published")
    func multiApparatusRoster() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)
        let incident = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154871" }
        )

        #expect(incident.dispatchedUnits == "P231, P234")
    }

    @Test("keeps the municipality code on a Prime Street verbatim")
    func municipalityCode() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)

        let scarborough = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154871" }
        )
        let northYork = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154878" }
        )

        #expect(scarborough.primeStreet == "LAWRENCE AVE, SC")
        #expect(northYork.primeStreet == "SHEPPARD AVE, NY")
    }

    @Test("keeps an Incident Type that our categories do not know")
    func unfamiliarIncidentTypeFallsThrough() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)
        let incident = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154871" }
        )

        #expect(incident.incidentType == "Alarm Single Source")
    }

    // MARK: - Degrading

    @Test("rejects a malformed payload rather than returning a partial snapshot")
    func malformedPayloadThrows() {
        #expect(throws: LiveCADParserError.malformedPayload) {
            try LiveCADParser.parse(Fixtures.malformedData)
        }
    }
}
