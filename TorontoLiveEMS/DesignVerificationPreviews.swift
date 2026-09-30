import SwiftUI
import TorontoLiveEMSKit

/// Incidents for the previews below. Not shipped data — the app's data comes from the
/// feed, and these are here so a screen can be looked at without a network.
///
/// Between them they cover every shape the feed publishes: a medical incident whose
/// location is an FSA, an ordinary addressable one, an escalated alarm, one with a long
/// apparatus roster, and the two blank shapes — no Prime Street, and no `units_disp`.
private enum PreviewIncidents {

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
        crossStreets: "ARDAGH ST / JANE ST",
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
private struct PreviewTable: View {
    var incidents: [Incident] = PreviewIncidents.all
    var timeFormat: DispatchTimeFormat = .twelveHour

    var body: some View {
        List {
            Section {
                ForEach(incidents) { incident in
                    IncidentRow(incident: incident, timeFormat: timeFormat)
                }
            } header: {
                CompactColumnHeader()
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
/// system setting and hunting for it.
#Preview("Table — accessibility text") {
    PreviewTable().environment(\.dynamicTypeSize, .accessibility3)
}

/// The largest size the system offers. This is the one issue #9 is about.
#Preview("Table — largest accessibility text") {
    PreviewTable().environment(\.dynamicTypeSize, .accessibility5)
}

// MARK: - The detail view, where the system's chrome is

/// The detail view carries the toolbar and the scroll edge effect, so it is the screen
/// where Reduce Transparency and Increase Contrast actually change something.
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

#Preview("Detail — increased contrast") {
    NavigationStack {
        IncidentDetailView(incident: PreviewIncidents.fire)
    }
    .environment(\.colorSchemeContrast, .increased)
}

#Preview("Detail — reduced transparency") {
    NavigationStack {
        IncidentDetailView(incident: PreviewIncidents.fire)
    }
    .environment(\.accessibilityReduceTransparency, true)
}

#Preview("Detail — reduced transparency, dark") {
    NavigationStack {
        IncidentDetailView(incident: PreviewIncidents.fire)
    }
    .preferredColorScheme(.dark)
    .environment(\.accessibilityReduceTransparency, true)
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
