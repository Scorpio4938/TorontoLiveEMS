import Foundation
import Testing
import TorontoLiveEMSKit

@Suite("Apple Maps handoff")
struct AppleMapsDestinationTests {

    private let point = Coordinate(
        latitude: 43.7180,
        longitude: -79.3780
    )

    private func incident(
        primeStreet: String? = "MARKHAM RD",
        crossStreets: String? = "MARKHAM RD / ELLESMERE RD"
    ) -> Incident {
        Incident(
            incidentNumber: "F1",
            primeStreet: primeStreet,
            crossStreets: crossStreets,
            dispatchTime: "2026-09-29T18:24:39",
            incidentType: "Alarm Single Source",
            alarmLevel: "0",
            area: "211",
            dispatchedUnits: nil
        )
    }

    private func call(crossStreets: String?) -> PoliceCall {
        PoliceCall(
            objectID: 1,
            occurrenceTime: Date(timeIntervalSince1970: 1_791_219_259),
            division: "D14",
            latitude: 43.7000,
            longitude: -79.4000,
            callTypeCode: "PERGU",
            callType: "PERSON WITH A GUN",
            crossStreets: crossStreets
        )
    }

    @Test("a fire incident hands over its cross streets and resolved point")
    func fireUsesCrossStreets() {
        let destination = incident().appleMapsDestination(
            location: .intersection("MARKHAM RD / ELLESMERE RD"),
            resolvedPoint: point
        )

        #expect(destination == AppleMapsDestination(
            coordinate: point,
            name: "MARKHAM RD / ELLESMERE RD"
        ))
    }

    @Test("a fire incident with only a street hands over what the detail shows")
    func fireUsesPrimeStreet() {
        let destination = incident(
            primeStreet: "LAWRENCE AVE, SC",
            crossStreets: nil
        ).appleMapsDestination(
            location: .street("LAWRENCE AVE"),
            resolvedPoint: point
        )

        #expect(destination?.name == "LAWRENCE AVE, SC")
    }

    @Test("a postal area has no point to hand over")
    func postalAreaHasNoDestination() {
        let destination = incident(
            primeStreet: "M6K",
            crossStreets: nil
        ).appleMapsDestination(
            location: .postalArea("M6K"),
            resolvedPoint: point
        )

        #expect(destination == nil)
    }

    @Test("a medical incident with cross streets still has no row")
    func postalIncidentWithCrossStreetsHasNoDestination() {
        let destination = incident(
            primeStreet: "M6K",
            crossStreets: "MARKHAM RD / ELLESMERE RD"
        ).appleMapsDestination(
            location: .intersection("MARKHAM RD / ELLESMERE RD"),
            resolvedPoint: point
        )

        #expect(destination == nil)
    }

    @Test("a point with no published address has nothing to name the pin with")
    func pointWithoutAddressHasNoDestination() {
        let destination = incident(
            primeStreet: nil,
            crossStreets: nil
        ).appleMapsDestination(
            location: .intersection("MARKHAM RD / ELLESMERE RD"),
            resolvedPoint: point
        )

        #expect(destination == nil)
    }

    @Test("an unresolved point has nothing to hand over")
    func unresolvedPointHasNoDestination() {
        #expect(
            incident().appleMapsDestination(
                location: .intersection("MARKHAM RD / ELLESMERE RD"),
                resolvedPoint: nil
            ) == nil
        )
    }

    @Test("a police call hands over its published point and intersection")
    func policeUsesIntersection() {
        let destination = call(crossStreets: "QUEEN ST W / SPADINA AVE").appleMapsDestination

        #expect(destination == AppleMapsDestination(
            coordinate: Coordinate(latitude: 43.7000, longitude: -79.4000),
            name: "QUEEN ST W / SPADINA AVE"
        ))
    }

    @Test("a police call with no intersection is still named")
    func policeWithoutIntersectionIsNamed() {
        let destination = call(crossStreets: nil).appleMapsDestination

        #expect(destination.name == "PERSON WITH A GUN")
    }
}
