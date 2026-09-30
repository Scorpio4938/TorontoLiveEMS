import SwiftUI
import TorontoLiveEMSKit

/// Incidents for the previews. Not shipped data — the app's data comes from the feed, and
/// these are here so a screen can be looked at without a network.
///
/// Internal rather than file-private so that previews elsewhere can render the same
/// incidents, which is what makes two treatments comparable: same data, same conditions.
///
/// Between them they cover every shape the feed publishes: a medical incident whose
/// location is an FSA, an ordinary addressable one, an escalated alarm with a long
/// apparatus roster, and the two blank shapes — no Prime Street, and no `units_disp`.
enum PreviewIncidents {

    static let medicalFSA = Incident(
        incidentNumber: "F26154815",
        primeStreet: "M6K",
        crossStreets: nil,
        dispatchTime: "2026-09-29T18:24:39",
        incidentType: "MEDICAL",
        alarmLevel: "0",
        area: "426",
        dispatchedUnits: "R346"
    )

    static let fire = Incident(
        incidentNumber: "F26154871",
        primeStreet: "LAWRENCE AVE, SC",
        crossStreets: "3950 LAWRENCE AVE E / 3967 LAWRENCE AVE E",
        dispatchTime: "2026-09-29T19:38:57",
        incidentType: "Fire - Residential",
        alarmLevel: "2",
        area: "234",
        dispatchedUnits: "P231, P234, A231, R234, C23"
    )

    /// The location is published as an escaped space, so Prime Street is blank.
    static let locationWithheld = Incident(
        incidentNumber: "F26154880",
        primeStreet: nil,
        crossStreets: "ARDAGH ST / JANE RD",
        dispatchTime: "2026-09-29T19:54:42",
        incidentType: "Vehicle - Personal Injury",
        alarmLevel: "0",
        area: "422",
        dispatchedUnits: nil
    )

    static let all = [medicalFSA, fire, locationWithheld]
}

// MARK: - The table

/// A `List` of rows rather than `ContentView`, which fetches on appear and would show a
/// loading state in the canvas.
///
/// It mirrors the screen deliberately, in the two places a preview would otherwise lie:
/// the rows are wrapped in a `NavigationLink` because that is what gives them the
/// disclosure chevron the column header reserves width for, and the header is shown only
/// at sizes the app would show it at. A preview that draws either differently is showing
/// an alignment the app does not have.
private struct PreviewTable: View {

    var incidents: [Incident] = PreviewIncidents.all
    var timeFormat: DispatchTimeFormat = .twelveHour

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            Section {
                ForEach(incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident)
                    } label: {
                        IncidentRow(incident: incident, timeFormat: timeFormat)
                    }
                }
            } header: {
                if !CompactTable.outgrowsTheGrid(dynamicTypeSize) {
                    CompactColumnHeader()
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview("Table — light") {
    PreviewTable()
}

#Preview("Table — dark") {
    PreviewTable().preferredColorScheme(.dark)
}

#Preview("Table — 24-hour") {
    PreviewTable(timeFormat: .twentyFourHour)
}

/// What the accessibility layout does, which is otherwise only reachable by changing a
/// system setting and then finding it.
#Preview("Table — accessibility text") {
    PreviewTable().environment(\.dynamicTypeSize, .accessibility3)
}

/// The largest size the system offers. This is the one issue #9 is about.
#Preview("Table — largest accessibility text") {
    PreviewTable().environment(\.dynamicTypeSize, .accessibility5)
}

// MARK: - The detail view, where the system's chrome is

/// The detail view carries the toolbar and the scroll edge effect, so it is the screen
/// where a change of appearance actually changes something.
#Preview("Detail — light") {
    NavigationStack {
        IncidentDetailView(incident: PreviewIncidents.fire)
    }
}

#Preview("Detail — dark") {
    NavigationStack {
        IncidentDetailView(incident: PreviewIncidents.fire)
    }
    .preferredColorScheme(.dark)
}

/// The medical case, whose location is a postal area and whose footer says so.
#Preview("Detail — withheld location") {
    NavigationStack {
        IncidentDetailView(incident: PreviewIncidents.locationWithheld)
    }
}

// MARK: - Settings

#Preview("Settings — light") {
    SettingsView()
}

#Preview("Settings — dark") {
    SettingsView().preferredColorScheme(.dark)
}

// NOTE: there were previews here for Increase Contrast and Reduce Transparency, and they
// were removed rather than kept. Both would need to set an environment value through a
// key path whose writability could not be confirmed from this machine, and a preview is
// not worth risking the build for — a failed preview fails the build.
//
// Both remain on issue #11's list, and both need the Simulator rather than the canvas:
// Settings → Accessibility → Display & Text Size → Increase Contrast, and
// Settings → Accessibility → Motion → Reduce Transparency.
