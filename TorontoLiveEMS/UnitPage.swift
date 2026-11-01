import Foundation
import SwiftUI
import TorontoLiveEMSKit

/// One unit code, and the two facts the catalogue can state about it.
///
/// **Apparatus and station, or nothing.** The code is the City's; the apparatus name is the longest
/// matching entry in the legend (with L read as Ladder); the station is the published station number the code's digits
/// happen to be. A code with no station shows no station rather than a labelled blank. There is no
/// roster of what is parked where, and no apology for the catalogue being a roster rather than a
/// census. A Commons photograph appears only when a file names this code; a unit with no such file
/// gets no photo, not a generic one.
///
/// **The live section reads the feed already in memory.** It makes no request of its own and adds no
/// refresh rule: the same `IncidentFeed` the Fire page and the map use is asked which incidents name
/// this code. A feed with no snapshot is a cold start, not idleness, so it says it is checking rather
/// than claiming the unit is not dispatched. Each live row carries the dispatch time on the same
/// clock, and from the same setting, as the Fire table.
struct UnitPage: View {

    let unit: FireUnit

    /// The shared fire feed, read for the live section and passed on so every page behind this one
    /// reads the same snapshot.
    let feed: IncidentFeed

    /// The reader's chosen clock, the same setting the Fire table reads.
    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    private var station: FireStation? {
        guard let number = unit.station else { return nil }
        return FireStations.bundled.station(number: number)
    }

    /// The optional Wikipedia text or photograph for this unit, when one exists.
    private var reference: WikipediaEntry? {
        WikipediaReference.bundled.unit(code: unit.code)
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

            if let reference, reference.summary != nil || reference.image != nil {
                Section {
                    if let summary = reference.summary {
                        Text(summary)
                    }

                    if let image = reference.image {
                        AsyncImage(url: URL(string: image.url)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            case .success(let loaded):
                                loaded
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Label("Photo unavailable", systemImage: "photo")
                                    .foregroundStyle(Color.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .accessibilityLabel("Photo of \(unit.code)")

                        if let page = URL(string: image.pageURL) {
                            Link("View on Wikimedia Commons", destination: page)
                                .tint(.blue)
                        }
                    }
                } header: {
                    Text(reference.summary == nil ? "Photo" : "About")
                } footer: {
                    if let image = reference.image {
                        Text("\(image.author), \(image.licence), via Wikimedia Commons.")
                    } else {
                        Text("Adapted from Wikipedia, “\(reference.title)”, \(reference.licence), retrieved \(reference.retrieved).")
                    }
                }
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
                        // The Fire page's card, with the fields this page has. The location is the
                        // main line; the incident type sits opposite it; the time is the line below.
                        // No incident number: it does not help a reader decide which incident this
                        // is, and the two fields that do are already on the card.
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
