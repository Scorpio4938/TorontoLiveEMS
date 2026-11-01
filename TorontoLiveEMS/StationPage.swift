import Foundation
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
/// photograph: the file knows neither, and the catalogue's premise is that it says only what it
/// knows. A Wikipedia history appears only when that station has an entry; the other stations get
/// no generic paragraph.
///
/// The units section is the catalogue's own cross-reference: the captured unit codes whose digits are
/// this station's number, each opening its unit page. It is absent when the app knows of none, in the
/// same way an unpublished office is.
///
/// **The live section asks about those units, not about the Area.** It shows incidents naming any
/// unit the catalogue places at this station, from the feed already in memory. It makes no request of
/// its own, and it does not claim the station responded: an incident's Area is a run area, which is a
/// different fact. The card is the Fire page's, and the clock is the reader's setting.
struct StationPage: View {

    let station: FireStation

    /// The shared fire feed, handed on to a unit page so its live section reads the same snapshot.
    let feed: IncidentFeed

    /// The reader's chosen clock, the same setting the Fire table reads.
    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    private var units: [FireUnit] {
        FireUnits.bundled.units(at: station.number)
    }

    /// The optional Wikipedia history for this station, when one exists.
    private var reference: WikipediaEntry? {
        WikipediaReference.bundled.station(number: station.number)
    }

    /// The incidents naming any unit the catalogue places here, or `nil` while there is no snapshot.
    ///
    /// The station is a location; the incident is linked to it through the units, not through the
    /// Area row. A station with no catalogued units has nothing to ask about.
    private var dispatchedIncidents: [Incident]? {
        guard !units.isEmpty else { return nil }
        return feed.incidents?.filter { incident in
            units.contains { $0.isDispatched(to: incident) }
        }
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

            if let reference, let extract = reference.extract {
                Section {
                    Text(extract)

                    if let url = URL(string: reference.url) {
                        Link("Read on Wikipedia", destination: url)
                            .tint(.blue)
                    }
                } header: {
                    Text("History")
                } footer: {
                    Text("Wikipedia, “\(reference.title)”, \(reference.licence), retrieved \(reference.retrieved). This is the history of the station's site; the current building may differ.")
                }
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

            if !units.isEmpty {
                Section {
                    live
                } header: {
                    Text("Dispatched Now")
                } footer: {
                    Text("Incidents currently naming one of the units the catalogue places at this station. This is not a claim that the station responded: an incident's Area is a run area, not a station.")
                }
            }
        }
        .navigationTitle("Station \(station.number)")
        .softScrollEdge()
    }

    @ViewBuilder
    private var live: some View {
        if let incidents = dispatchedIncidents {
            if incidents.isEmpty {
                Text("None of this station's units are currently dispatched.")
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident, feed: feed)
                    } label: {
                        CompactCardRow(
                            row: incident,
                            columns: [.primeStreet, .incidentType, .dispatchTime],
                            timeFormat: dispatchTimeFormat
                        )
                    }
                }
            }
        } else if let failure = feed.failureMessage {
            Text(failure)
                .foregroundStyle(Color.secondary)
        } else {
            HStack(spacing: 6) {
                ProgressView()
                Text("Checking the live feed…")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        if let station = FireStations.bundled.station(number: 231) {
            StationPage(station: station, feed: PreviewIncidents.feed())
        }
    }
}
