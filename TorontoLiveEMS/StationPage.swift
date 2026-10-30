import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// One fire station, with the facts the City publishes about it.
///
/// **Everything here is published or absent.** Number, address, municipality, year built and ward
/// are on every station row in the City's file, so they are always shown. Offices are published on
/// only some stations, so the section is absent when there are none — an absent field never becomes
/// a labelled blank row.
///
/// **The map is a locator, not a live map.** The City publishes one point for the station, so this is
/// one pin around that point and nothing else. There is no roster of what is parked there, and no
/// photograph: the file knows neither, and the catalogue's premise is that it says only what it knows.
///
/// The units section is the catalogue's own cross-reference: the captured unit codes whose digits are
/// this station's number, each opening its unit page. It is absent when the app knows of none, in the
/// same way an unpublished office is.
struct StationPage: View {

    let station: FireStation

    /// The shared fire feed, handed on to a unit page so its live section reads the same snapshot.
    let feed: IncidentFeed

    private var units: [FireUnit] {
        FireUnits.bundled.units(at: station.number)
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Number", value: "\(station.number)")
                LabeledContent("Address", value: station.address)
                LabeledContent("Municipality", value: station.municipality)
                LabeledContent("Year Built", value: "\(station.yearBuilt)")
                LabeledContent("Ward", value: "\(station.ward.number) · \(station.ward.name)")
            } header: {
                Text("Station")
            } footer: {
                Text("A station is the numbered fire facility the City publishes. An incident's Area is the run area the City files it under, numbered as a station; it is not necessarily the station that responded.")
            }

            if !station.offices.isEmpty {
                Section {
                    ForEach(station.offices, id: \.self) { office in
                        Text(office)
                    }
                } header: {
                    Text("Offices")
                }
            }

            Section {
                ReferenceLocationMap(
                    title: "Station \(station.number)",
                    coordinate: CLLocationCoordinate2D(
                        latitude: station.coordinate.latitude,
                        longitude: station.coordinate.longitude
                    )
                )
            }

            if !units.isEmpty {
                Section {
                    ForEach(units) { unit in
                        NavigationLink {
                            UnitPage(unit: unit, feed: feed)
                        } label: {
                            FireUnitRow(unit: unit)
                        }
                    }
                } header: {
                    Text("Units")
                }
            }
        }
        .navigationTitle("Station \(station.number)")
        .softScrollEdge()
    }
}

#Preview {
    NavigationStack {
        if let station = FireStations.bundled.station(number: 231) {
            StationPage(station: station, feed: PreviewIncidents.feed())
        }
    }
}
