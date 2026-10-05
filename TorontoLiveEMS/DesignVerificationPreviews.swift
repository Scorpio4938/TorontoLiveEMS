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

    /// The same incidents as the feed would have handed them over, for previews of a whole
    /// screen rather than of one view.
    ///
    /// `IncidentFeed` takes its fetch as a parameter precisely so this is possible: a preview can
    /// hand the app a fixed snapshot and never touch the City's server. Without it, `#Preview`
    /// could only ever render "Loading active incidents".
    static let snapshot = LiveCADSnapshot(
        updatedFromDatabaseAt: "2026-09-29 20:00:01",
        incidents: all
    )
}

/// What the status line says in the previews. The real value is the City's refresh tick,
/// which lands on a five-minute boundary — see `IncidentFeed.status`.
private let previewStatus = FeedStatus(
    text: "City data as of 2026-09-29 20:00:01",
    isStale: false
)

// MARK: - The two arrangements
//
// These render the real list views, not copies. A preview that drew its own version could
// disagree with the app about the thing it exists to show — which the first draft of this
// file did, in both layouts at once.

/// The real table over the sample incidents, so a preview cannot show a layout the app does not
/// have. The columns are the fire feed's own, from the package — the previews do not carry a second
/// copy of them, which is what the eight call sites below used to do.
private func fireTable(
    _ timeFormat: DispatchTimeFormat,
    status: FeedStatus = previewStatus
) -> some View {
    CompactTableList(
        rows: PreviewIncidents.all,
        columns: CompactColumn<Incident>.fire,
        timeFormat: timeFormat,
        status: status
    ) { incident in
        IncidentDetailView(incident: incident)
    }
}

/// The real cards over the same data, in the fire feed's card order.
private func fireCards(
    _ timeFormat: DispatchTimeFormat,
    status: FeedStatus = previewStatus
) -> some View {
    CardsList(
        rows: PreviewIncidents.all,
        columns: CompactColumn<Incident>.fireCard,
        timeFormat: timeFormat,
        status: status
    ) { incident in
        IncidentDetailView(incident: incident)
    }
}

#Preview("Table — light") {
    fireTable(.twelveHour)
}

#Preview("Table — dark") {
    fireTable(.twelveHour)
        .preferredColorScheme(.dark)
}

#Preview("Table — 24-hour") {
    fireTable(.twentyFourHour)
}

/// What the accessibility layout does, which is otherwise only reachable by changing a
/// system setting and then finding it.
#Preview("Table — accessibility text") {
    fireTable(.twelveHour)
        .environment(\.dynamicTypeSize, .accessibility3)
}

/// The largest size the system offers. This is the one issue #9 is about.
#Preview("Table — largest accessibility text") {
    fireTable(.twelveHour)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Cards — light") {
    fireCards(.twelveHour)
}

#Preview("Cards — dark") {
    fireCards(.twelveHour)
        .preferredColorScheme(.dark)
}

/// Cards are already a stack of two lines, so there is no separate accessibility layout
/// for them — this is what they do at those sizes, which should simply be bigger.
#Preview("Cards — largest accessibility text") {
    fireCards(.twelveHour)
        .environment(\.dynamicTypeSize, .accessibility5)
}

/// The status line's warning state, which is otherwise only reachable by breaking the
/// network mid-session.
#Preview("Cards — last result kept") {
    fireCards(
        .twelveHour,
        status: FeedStatus(
            text: "City data as of 2026-09-29 20:00:01 · showing the last result",
            isStale: true
        )
    )
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

// MARK: - The app icon

/// The icon at the sizes iOS actually draws it, under the mask it applies.
///
/// Here rather than in a chat message because there is no other way to show it. 60pt is the
/// Home Screen, 40pt a notification, 29pt Settings and Spotlight — the size that decides
/// whether a mark is a mark or a smudge.
///
/// Delete this section and the three `IconAppearance*` asset folders once the icon is
/// settled. They exist only to be looked at; the icon itself is in `AppIcon.appiconset`.
private struct IconPreview: View {
    let asset: String
    let label: String

    /// iOS rounds icons on a continuous corner arc at about 22.4% of the edge, so the
    /// candidates are shown as they will appear rather than as raw squares.
    private func icon(_ size: CGFloat) -> some View {
        Image(asset)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach([CGFloat(60), 40, 29], id: \.self) { size in
                icon(size)
            }
            Text(label).font(.footnote).foregroundStyle(Color.secondary)
        }
        .padding()
    }
}

#Preview("Icon — light") {
    IconPreview(asset: "IconAppearanceLight", label: "light")
}

#Preview("Icon — dark") {
    IconPreview(asset: "IconAppearanceDark", label: "dark")
        .preferredColorScheme(.dark)
}

#Preview("Icon — tinted") {
    IconPreview(asset: "IconAppearanceTinted", label: "tinted")
}
