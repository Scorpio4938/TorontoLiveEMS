import Foundation
import Testing
import TorontoLiveEMSKit

@Suite("Incident placement check")
struct IncidentPlacementCheckTests {

    /// The mean-radius sphere's own conversion from metres to degrees of latitude.
    ///
    /// The fixtures are built this way so they can name 6.84 km and 10.5 km directly. The test
    /// pins the decision at those distances, not the geodesy: the threshold's margin is far
    /// larger than the difference between the mean sphere and a local radius.
    private let metresPerDegreeLatitude = 111_194.9

    private func point(
        northOf station: FireStation,
        metres: Double
    ) -> IncidentPlacementCheck.Coordinate {
        IncidentPlacementCheck.Coordinate(
            latitude: station.coordinate.latitude + metres / metresPerDegreeLatitude,
            longitude: station.coordinate.longitude
        )
    }

    /// A point due east of a station, at the given distance.
    ///
    /// The longitude term shrinks with latitude, so the degree offset is divided by the cosine.
    private func point(
        eastOf station: FireStation,
        metres: Double
    ) -> IncidentPlacementCheck.Coordinate {
        let latitude = station.coordinate.latitude
        let degrees = metres
            / (metresPerDegreeLatitude * cos(latitude * .pi / 180))
        return IncidentPlacementCheck.Coordinate(
            latitude: latitude,
            longitude: station.coordinate.longitude + degrees
        )
    }

    private func incident(
        area: String = "211",
        primeStreet: String = "MARKHAM RD",
        crossStreets: String? = "MARKHAM RD / ELLESMERE RD",
        incidentType: String = "Alarm Single Source"
    ) -> Incident {
        Incident(
            incidentNumber: "F1",
            primeStreet: primeStreet,
            crossStreets: crossStreets,
            dispatchTime: "2026-09-29T18:24:39",
            incidentType: incidentType,
            alarmLevel: "0",
            area: area,
            dispatchedUnits: nil
        )
    }

    @Test("the threshold is one named constant, 10 km")
    func thresholdIsTenKilometres() {
        #expect(IncidentPlacementCheck.thresholdMetres == 10_000)
    }

    @Test("station 211's worst real run-area distance, 6.84 km, is plausible")
    func worstRealAreaPasses() throws {
        let station = try #require(FireStations.bundled.station(number: 211))

        // The run-area geometry is not in this repository, so the point is synthesised at the
        // measured distance from station 211's published coordinate. The 6.84 km is the fact
        // from the City's areas; this pins what the check does at that distance.
        #expect(
            !IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(incident()),
                resolvedPoint: point(northOf: station, metres: 6_840),
                station: station
            )
        )
    }

    @Test("a point past 10 km may be off")
    func pastTheThresholdWarns() throws {
        let station = try #require(FireStations.bundled.station(number: 211))

        #expect(
            IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(incident()),
                resolvedPoint: point(northOf: station, metres: 10_500),
                station: station
            )
        )
    }

    @Test("a point east of the station is measured through longitude")
    func eastOfStationWarns() throws {
        let station = try #require(FireStations.bundled.station(number: 211))

        #expect(
            IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(incident()),
                resolvedPoint: point(eastOf: station, metres: 10_500),
                station: station
            )
        )
    }

    @Test("a street-name geocode is a point, so it is checked")
    func streetNameIsCheckedAsAPoint() throws {
        let station = try #require(FireStations.bundled.station(number: 211))
        let street = incident(
            primeStreet: "LAWRENCE AVE, SC",
            crossStreets: nil
        )

        #expect(IncidentLocation.from(street) == .street("LAWRENCE AVE"))
        #expect(
            IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(street),
                resolvedPoint: point(northOf: station, metres: 10_500),
                station: station
            )
        )
    }

    @Test("no point stays silent")
    func noPointStaysSilent() throws {
        let station = try #require(FireStations.bundled.station(number: 211))

        #expect(
            !IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(incident()),
                resolvedPoint: nil,
                station: station
            )
        )
    }

    @Test("no station stays silent")
    func noStationStaysSilent() throws {
        let station = try #require(FireStations.bundled.station(number: 211))

        #expect(
            !IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(incident(area: "999")),
                resolvedPoint: point(northOf: station, metres: 10_500),
                station: nil
            )
        )
    }

    @Test("a postal area is never a point, even when a fallback centre resolved")
    func postalAreaStaysSilent() throws {
        let station = try #require(FireStations.bundled.station(number: 211))

        #expect(
            !IncidentPlacementCheck.shouldWarn(
                location: IncidentLocation.from(incident(
                    primeStreet: "M1G",
                    crossStreets: nil,
                    incidentType: "MEDICAL"
                )),
                resolvedPoint: point(northOf: station, metres: 10_500),
                station: station
            )
        )
    }
}
