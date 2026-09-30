import SwiftUI
import TorontoLiveEMSKit

/// Incidents for the previews. Not shipped data — the app's data comes from the feed, and
/// these are here so a screen can be looked at without a network.
///
/// Internal rather than file-private so that previews elsewhere can render the same
/// incidents, which is what makes two arrangements comparable: same data, same conditions.
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
        crossStreets: "ARDAGH ST / JANE ST",
        dispatchTime: "2026-09-29T19:54:42",
        incidentType: "Vehicle - Personal Injury",
        alarmLevel: "0",
        area: "422",
        dispatchedUnits: nil
    )

    static let all = [medicalFSA, fire, locationWithheld]
}

// MARK: - The two arrangements
//
// These render the real list views, not copies. A preview that drew its own version could
// disagree with the app about the thing it exists to show — which the first draft of this
// file did, in both layouts at once.

#Preview("Table — light") {
    CompactTableList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
}

#Preview("Table — dark") {
    CompactTableList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
        .preferredColorScheme(.dark)
}

#Preview("Table — 24-hour") {
    CompactTableList(incidents: PreviewIncidents.all, timeFormat: .twentyFourHour)
}

/// What the accessibility layout does, which is otherwise only reachable by changing a
/// system setting and then finding it.
#Preview("Table — accessibility text") {
    CompactTableList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
        .environment(\.dynamicTypeSize, .accessibility3)
}

/// The largest size the system offers. This is the one issue #9 is about.
#Preview("Table — largest accessibility text") {
    CompactTableList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Cards — light") {
    CardsList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
}

#Preview("Cards — dark") {
    CardsList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
        .preferredColorScheme(.dark)
}

/// Cards are already a stack of two lines, so there is no separate accessibility layout
/// for them — this is what they do at those sizes, which should simply be bigger.
#Preview("Cards — largest accessibility text") {
    CardsList(incidents: PreviewIncidents.all, timeFormat: .twelveHour)
        .environment(\.dynamicTypeSize, .accessibility5)
}

// MARK: - The detail view, where the system's chrome is

/// The detail view carries the toolbar and the scroll edge effect, so it is the screen
/// where a change of appearance actually changes something. It is also where the cards
/// layout got its block from, so it is the reference for that.
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
