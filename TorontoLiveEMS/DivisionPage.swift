import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// One police division, with the facts the City publishes about it and the calls on it now.
///
/// **The division as the feed writes it.** The boundary file stores `14`; the feed and every screen
/// write `D14`, so that is the title and the fact row.
///
/// **The facility is a separate published record.** Three of the 19 divisions have no facility row,
/// so their pages show no address, no postal code and no map rather than labelled blanks. The
/// facility's point is published, so the locator map is a pin and never a boundary: this page says
/// *where the division's building is*, not what ground the division covers.
///
/// **The live section reads the calls already in memory.** It makes no request of its own and adds no
/// refresh rule. A cold start says it is checking; a loaded feed with no matching calls says none are
/// filed there at the moment.
struct DivisionPage: View {

    let division: PoliceDivision

    /// The shared police feed, read for the live section and handed on to a call's detail view.
    let policeFeed: PoliceCallFeed

    private var facility: PoliceFacility? {
        PoliceFacilities.bundled.facility(forPublished: division.number)
    }

    /// The calls currently filed under this division, or `nil` while there is no snapshot to ask.
    private var calls: [PoliceCall]? {
        policeFeed.calls?.filter { division.matches(published: $0.division) }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Division", value: division.feedCode)
            } header: {
                Text("Division")
            } footer: {
                Text("A division is a Toronto Police Service area. The number is the feed's spelling; the address, when there is one, is the City's facility record for that division.")
            }

            if let facility = facility {
                Section {
                    LabeledContent("Address", value: facility.address)
                    LabeledContent("Postal Code", value: facility.postalCode)
                } header: {
                    Text("Facility")
                }

                Section {
                    ReferenceLocationMap(
                        title: division.feedCode,
                        coordinate: CLLocationCoordinate2D(
                            latitude: facility.coordinate.latitude,
                            longitude: facility.coordinate.longitude
                        )
                    )
                }
            }

            Section {
                live
            } header: {
                Text("Calls Now")
            }
        }
        .navigationTitle(division.feedCode)
        .softScrollEdge()
    }

    @ViewBuilder
    private var live: some View {
        if let calls = calls {
            if calls.isEmpty {
                Text("No calls in this division at the moment.")
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(calls) { call in
                    NavigationLink {
                        PoliceCallDetailView(call: call, policeFeed: policeFeed)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(call.callType)
                            Text(call.crossStreets ?? NotProvided.mark)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
        } else if let failure = policeFeed.failureMessage {
            Text(failure)
                .foregroundStyle(Color.secondary)
        } else {
            HStack(spacing: 6) {
                ProgressView()
                Text("Checking the live calls…")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

#Preview("Division — with a facility") {
    NavigationStack {
        if let division = PoliceDivisions.bundled.division(forPublished: "D14") {
            DivisionPage(division: division, policeFeed: PreviewCalls.feed())
        }
    }
}

#Preview("Division — no facility") {
    NavigationStack {
        if let division = PoliceDivisions.bundled.division(forPublished: "D00") {
            DivisionPage(division: division, policeFeed: PreviewCalls.feed())
        }
    }
}
