import SwiftUI
import TorontoLiveEMSKit

/// One police division, with the facts the City publishes about it and the calls on it now.
///
/// **The division as the feed writes it.** The boundary file stores `14`; the feed and every screen
/// write `D14`, so that is the title and the fact row.
///
/// **The facility is a separate published record.** Three of the 19 divisions have no facility row,
/// so their pages show no address and no postal code rather than labelled blanks. The map is the
/// division's published area — the ground the City drew — and the address is text above it; a pin
/// would narrow a division to its building, which is not what the division is.
///
/// **The live section reads the calls already in memory.** It makes no request of its own and adds no
/// refresh rule. A cold start says it is checking; a loaded feed with no matching calls says none are
/// filed there at the moment. Each live row is the Police page's card with the fields this page has:
/// intersection, call type and occurrence time, in that card's arrangement and on the same clock.
/// Division is omitted because this whole page is one division.
struct DivisionPage: View {

    let division: PoliceDivision

    /// The shared police feed, read for the live section and handed on to a call's detail view.
    let policeFeed: PoliceCallFeed

    /// The reader's chosen clock, the same setting the Police table reads.
    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    /// Whether a call type is shown as words or as the Service's code, the same setting the Police
    /// page reads.
    @AppStorage(SettingsKey.policeCallTypeStyle)
    private var policeCallTypeStyle: PoliceCallTypeStyle = .words

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
            }

            Section {
                // A division is ground. The area is drawn whether or not the City publishes a
                // facility address for it, because the area is the thing the division is.
                DivisionAreaMap(division: division)
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
                        // The Police page's card, with the fields this page has. The intersection
                        // is the main line; the call type sits opposite it; the time is the line
                        // below. Division is omitted because this whole page is one division.
                        CompactCardRow(
                            row: call,
                            columns: [
                                .crossStreets,
                                .callType(style: policeCallTypeStyle),
                                .occurrenceTime,
                            ],
                            timeFormat: dispatchTimeFormat
                        )
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
