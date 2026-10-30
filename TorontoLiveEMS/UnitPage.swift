import SwiftUI
import TorontoLiveEMSKit

/// One unit code, and the two facts the catalogue can state about it.
///
/// **Apparatus and station, or nothing.** The code is the City's; the apparatus name is the longest
/// matching entry in the City's legend; the station is the published station number the code's digits
/// happen to be. A code with no station shows no station rather than a labelled blank. There is no
/// photograph, no roster of what is parked where, and no apology for the catalogue being one capture
/// rather than a census.
///
/// **The live section reads the feed already in memory.** It makes no request of its own and adds no
/// refresh rule: the same `IncidentFeed` the Fire page and the map use is asked which incidents name
/// this code. A feed with no snapshot is a cold start, not idleness, so it says it is checking rather
/// than claiming the unit is not dispatched.
struct UnitPage: View {

    let unit: FireUnit

    /// The shared fire feed, read for the live section and passed on so every page behind this one
    /// reads the same snapshot.
    let feed: IncidentFeed

    private var station: FireStation? {
        guard let number = unit.station else { return nil }
        return FireStations.bundled.station(number: number)
    }

    /// The incidents currently naming this unit, or `nil` while there is no snapshot to ask.
    private var dispatchedIncidents: [Incident]? {
        feed.incidents?.filter { unit.isDispatched(to: $0) }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Code", value: unit.code)
                if let name = unit.name {
                    LabeledContent("Apparatus", value: name)
                }
                if let station = self.station {
                    NavigationLink {
                        StationPage(station: station, feed: feed)
                    } label: {
                        LabeledContent("Station", value: "\(station.number)")
                    }
                }
            } header: {
                Text("Unit")
            }

            Section {
                live
            } header: {
                Text("Dispatched Now")
            }
        }
        .navigationTitle(unit.code)
        .softScrollEdge()
    }

    @ViewBuilder
    private var live: some View {
        if let incidents = dispatchedIncidents {
            if incidents.isEmpty {
                // Not a blank. An empty section would read as a loading fault; this says the fact
                // the loaded snapshot supports.
                Text("This unit is not currently dispatched.")
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident, feed: feed)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(incident.incidentNumber)
                            Text(incident.primeStreet ?? incident.crossStreets ?? NotProvided.mark)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        } else if let failure = feed.failureMessage {
            Text(failure)
                .foregroundStyle(Color.secondary)
        } else {
            // Cold start. The feed is being read at launch, and this page did not make a second
            // request to find that out.
            HStack(spacing: 6) {
                ProgressView()
                Text("Checking the live feed…")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview("Unit — at a station") {
    NavigationStack {
        if let unit = FireUnits.bundled.unit(code: "P331") {
            UnitPage(unit: unit, feed: PreviewIncidents.feed())
        }
    }
}

#Preview("Unit — no station") {
    NavigationStack {
        UnitPage(
            unit: FireUnit(code: "C23", stations: FireStations.bundled),
            feed: PreviewIncidents.feed()
        )
    }
}
