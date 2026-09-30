import Testing
import TorontoLiveEMSKit

@Suite("Postal-area locations")
struct IncidentLocationTests {

    private func incident(primeStreet: String?) -> Incident {
        return Incident(
            incidentNumber: "F0",
            primeStreet: primeStreet,
            crossStreets: nil,
            dispatchTime: "2026-09-29T18:24:39",
            incidentType: "MEDICAL",
            alarmLevel: "0",
            area: "426",
            dispatchedUnits: nil
        )
    }

    @Test("recognises a published postal area")
    func recognisesPostalArea() {
        #expect(incident(primeStreet: "M6K").isLocationPostalArea)
        #expect(incident(primeStreet: "M5T").isLocationPostalArea)
    }

    @Test("does not mistake a street name for a postal area")
    func rejectsStreetNames() {
        #expect(!incident(primeStreet: "LAWRENCE AVE, SC").isLocationPostalArea)
        #expect(!incident(primeStreet: "KING ST").isLocationPostalArea)
        #expect(!incident(primeStreet: "M6").isLocationPostalArea)
        #expect(!incident(primeStreet: "MEDICAL").isLocationPostalArea)
        #expect(!incident(primeStreet: nil).isLocationPostalArea)
    }

    @Test("agrees with the captured feed")
    func agreesWithTheCapturedFeed() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)

        let medical = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154815" }
        )
        let addressable = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154871" }
        )

        #expect(medical.isLocationPostalArea)
        #expect(!addressable.isLocationPostalArea)
    }
}
