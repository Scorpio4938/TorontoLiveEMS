import Foundation
import Testing

import TorontoLiveEMSKit

/// The generated station file, checked against facts that do not come from the file.
///
/// These are not tests of code so much as tests of data: that the resource is in the bundle, that
/// the import kept the 84 stations and dropped the training site, that the fields a screen would
/// name are actually there, and that the coordinates are degrees in Toronto. A reference file can
/// be wrong in ways that still look plausible, and every one of them is caught here instead of on
/// a screen.
@Suite("Fire stations")
struct FireStationsTests {

    private var stations: FireStations { FireStations.bundled }

    /// Toronto's own corner of the world, generously bounded.
    private let toronto = (latitudes: 43.5 ... 43.9, longitudes: -79.7 ... -79.1)

    @Test("the bundled file loads")
    func theFileLoads() {
        #expect(stations.count == 84, "the published file has 85 rows; 84 are fire stations")
        #expect(stations.stations.count == 84)
        #expect(stations.numbers.count == 84)
        #expect(stations.numbers == stations.numbers.sorted())
        #expect(!stations.source.isEmpty)
        #expect(!stations.licence.isEmpty)
        #expect(!stations.retrieved.isEmpty)
    }

    @Test("the training site is not a station")
    func trainingSiteIsExcluded() {
        // 25 Old Eglinton Ave is published with TYPE_DESC "Ops Training" and no station number.
        // It is a City facility, not a fire station, and the import filters on the published type
        // rather than counting rows.
        #expect(!stations.stations.contains { $0.address == "25 Old Eglinton Ave" })
        #expect(!stations.stations.contains { $0.offices.contains("Fire Burn House & Training Dome") })
        #expect(!stations.numbers.contains(0))
    }

    @Test("every station has the facts the file promises")
    func everyStationHasItsFacts() {
        for station in stations.stations {
            #expect((100 ... 999).contains(station.number), "\(station.number) is not a station number")
            #expect(!station.address.isEmpty)
            #expect(!station.municipality.isEmpty)
            #expect(station.yearBuilt > 1800 && station.yearBuilt <= 2100)
            #expect(station.ward.number > 0)
            #expect(!station.ward.name.isEmpty)
            #expect(station.offices.allSatisfy { !$0.isEmpty })
            #expect(toronto.latitudes.contains(station.coordinate.latitude))
            #expect(toronto.longitudes.contains(station.coordinate.longitude))
        }
    }

    @Test("a known station is the one the feed's number names")
    func knownStation() throws {
        let station = try #require(stations.station(number: 231))

        #expect(station.address == "740 Markham Rd")
        #expect(station.municipality == "Scarborough")
        #expect(station.yearBuilt == 1960)
        #expect(station.ward.number == 24)
        #expect(station.ward.name == "Scarborough-Guildwood")
        #expect(station.offices.isEmpty)
        #expect(abs(station.coordinate.latitude - 43.764644) < 0.00001)
        #expect(abs(station.coordinate.longitude - -79.227788) < 0.00001)
    }

    @Test("the offices a station houses are the City's words")
    func officesArePublished() throws {
        let station = try #require(stations.station(number: 221))
        #expect(station.offices == ["Division Commander / Platoon Chiefs"])

        // `None` is the City's placeholder for no office, not an office with that name.
        #expect(stations.stations.allSatisfy { !$0.offices.contains("None") })
        #expect(stations.stations.contains { !$0.offices.isEmpty })
        #expect(stations.stations.contains { $0.offices.isEmpty })
    }

    @Test("the source, licence and retrieval date are recorded")
    func provenanceIsRecorded() {
        #expect(stations.source.contains("toronto.ca"))
        #expect(stations.source.contains("fire-station-locations"))
        #expect(stations.licence.contains("Open Government Licence"))
        #expect(stations.licence.contains("Toronto"))
        #expect(stations.retrieved.count == 10)
        #expect(stations.retrieved.split(separator: "-").count == 3)
    }

    @Test("a station the file does not know is nil")
    func unknownStation() {
        #expect(stations.station(number: 999) == nil)
        #expect(stations.station(number: 0) == nil)
    }

    @Test("something that is not the file is refused")
    func refusesRubbish() {
        #expect(throws: (any Error).self) {
            try FireStations(data: Data("not json".utf8))
        }
    }

    @Test("two rows for one station number are refused")
    func refusesDuplicateStation() {
        let document = """
            {"source":"s","licence":"l","retrieved":"2026-10-29","stations":[
              {"number":231,"address":"740 Markham Rd","municipality":"Scarborough",
               "yearBuilt":1960,"ward":{"number":24,"name":"Scarborough-Guildwood"},
               "offices":[],"coordinate":{"latitude":43.764644,"longitude":-79.227788}},
              {"number":231,"address":"a second answer","municipality":"Scarborough",
               "yearBuilt":1960,"ward":{"number":24,"name":"Scarborough-Guildwood"},
               "offices":[],"coordinate":{"latitude":43.764644,"longitude":-79.227788}}
            ]}
            """

        #expect(throws: FireStationsError.duplicateStation(231)) {
            try FireStations(data: Data(document.utf8))
        }
    }
}
