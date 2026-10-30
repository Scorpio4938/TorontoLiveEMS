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
                StationLocationMap(station: station)
            }

            if !units.isEmpty {
                Section {
                    ForEach(units) { unit in
                        NavigationLink {
                            UnitPage(unit: unit, feed: feed)
                        } label: {
                            HStack {
                                Text(unit.code)
                                Spacer()
                                if let name = unit.name {
                                    Text(name)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
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

/// The station's one published point, on a small map.
///
/// **No geocoder.** A station's coordinate is published in the reference file, so this is the one map
/// in the app that never asks Apple where the thing is. The pin is a pin rather than a circle because
/// the City published a point, not an area.
private struct StationLocationMap: View {

    let station: FireStation

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: station.coordinate.latitude,
            longitude: station.coordinate.longitude
        )
    }

    var body: some View {
        Map(
            initialPosition: .region(
                IncidentMapScale.region(around: coordinate, isArea: false)
            ),
            interactionModes: [.pan, .zoom]
        ) {
            Marker("Station \(station.number)", coordinate: coordinate)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    NavigationStack {
        if let station = FireStations.bundled.station(number: 231) {
            StationPage(station: station, feed: PreviewIncidents.feed())
        }
    }
}
