import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Every active incident the feed published a location for, on one map.
///
/// **One mark per place, not per incident.** The live capture holds fifteen incidents in
/// thirteen places, with two FSAs holding two incidents each. A mark per incident would stack two
/// identical circles and leave one of them unreachable from the map, while the map claimed to
/// show all of them. So a place is what is drawn, and tapping it shows every incident there.
///
/// **Nothing published means nothing drawn, and nothing said about it.** An incident with no
/// Prime Street and no Cross Street has nowhere to be. Saying so on the map would be a notice
/// about a value the feed never sent, and the list is the record of what is active.
///
/// **"Finding N more…" counts places, and is a loading indicator rather than a completeness
/// notice.** Apple's geocoder takes one address string at a time against a service with
/// undisclosed limits, so the marks arrive over some seconds. Without it a reader watching six
/// circles appear would conclude the map was wrong. Places rather than incidents because a place
/// is what a mark is: "3 more" when three incidents share one corner would promise three marks
/// and deliver one.
///
/// **Selection goes through `.tag` and `selection:`, not a tap gesture.** A `MapCircle` is
/// `MapContent` and not a `View`, so it cannot carry an `.onTapGesture` at all — the only way to
/// make an area selectable is to tag it. Using the same mechanism for pins as for areas is worth
/// more than the simpler gesture would have been on half of them.
struct IncidentsMapPage: View {

    let feed: IncidentFeed

    @State private var geocoder = IncidentGeocoder()
    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)
    @State private var selected: IncidentLocation?

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    /// A place the feed named, once, with however many incidents are there.
    private struct Place: Identifiable {
        let location: IncidentLocation
        let resolved: IncidentGeocoder.Resolved
        let incidents: [Incident]

        var id: IncidentLocation { location }
    }

    var body: some View {
        Map(position: $position, selection: $selected) {
            ForEach(places) { place in
                if place.resolved.isArea {
                    // An FSA. Drawing it as a pin would put a medical incident at the centre of a
                    // neighbourhood and call it a location — ADR-0004 forbids narrowing it, and
                    // this is the map's version of not narrowing it. The same circle the detail
                    // map draws, from the same constant.
                    MapCircle(center: place.resolved.coordinate, radius: IncidentMapScale.postalAreaRadius)
                        .foregroundStyle(Color.orange.opacity(0.20))
                        .stroke(Color.orange, lineWidth: 1)
                        .tag(place.location)
                } else {
                    Annotation("", coordinate: place.resolved.coordinate) {
                        IncidentPin(incident: place.incidents[0])
                    }
                    .annotationTitles(.hidden)
                    .tag(place.location)
                }
            }

            // The card, drawn inside the map so it needs no coordinate-to-point conversion — and
            // so it pans and zooms with the thing it belongs to. Anchored to the rim for an area,
            // never to its middle.
            if let place = selectedPlace {
                Annotation("", coordinate: anchor(for: place), anchor: .bottom) {
                    callout(for: place)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls {
            MapCompass()
            // `alignment` given rather than left off. `MapScaleView` has two initialisers and
            // every parameter of both has a default, so a bare `MapScaleView()` is ambiguous
            // between them — it reads as the natural call and is not one.
            MapScaleView(alignment: .leading)
        }
        // **This page sits under no bar; its title and controls float, from `RootView`.**
        //
        // The band chased through seven attempts was the navigation bar's own glass, and the
        // build that hid the bar proved it: no bar, no band. `toolbarBackgroundVisibility`
        // cannot remove that glass on this OS, and the scroll-edge settings were no-ops — those
        // APIs configure scroll views, and a map page has none. So the map tab ships with no
        // navigation bar at all, Apple Maps' pattern, and the page's name and its two controls
        // float over the map in glass capsules. The full record is in
        // `docs/design-decisions.md`, *The bar and the map page*.
        // Bottom-trailing, above the tab bar, as a bare line rather than a boxed strip.
        .overlay(alignment: .bottomTrailing) { notice }
        // Keyed on the places, so a new set of them is looked up and the same set is not.
        .task(id: lookedUp) {
            await geocoder.resolve(lookedUp)
        }
    }

    // MARK: - What the feed gave us

    /// Every distinct place the feed named, in the order the incidents were published.
    ///
    /// Nothing is filtered by whether it can be found: an FSA and a cross street are both
    /// questions worth asking, and `IncidentGeocoder` is the thing that knows which of them
    /// cannot be asked at all.
    private var lookedUp: [IncidentLocation] {
        var seen: [IncidentLocation] = []
        for incident in feed.snapshot?.incidents ?? [] {
            let location = IncidentLocation.from(incident)
            guard location != .unpublished, !seen.contains(location) else { continue }
            seen.append(location)
        }
        return seen
    }

    /// The places that can be drawn: a location, and an answer for it.
    private var places: [Place] {
        let incidents = feed.snapshot?.incidents ?? []
        return lookedUp.compactMap { location in
            guard let resolved = geocoder.known(location) else { return nil }
            return Place(
                location: location,
                resolved: resolved,
                incidents: incidents.filter { IncidentLocation.from($0) == location }
            )
        }
    }

    private var selectedPlace: Place? {
        guard let selected else { return nil }
        return places.first { $0.location == selected }
    }

    /// Places still being looked up, counted as places because a place is what a mark is.
    private var pendingPlaces: Int {
        lookedUp.filter { geocoder.outcome(of: $0) == .pending }.count
    }

    /// Where a place's card hangs from: above a pin, above an area's rim, never a middle.
    private func anchor(for place: Place) -> CLLocationCoordinate2D {
        guard place.resolved.isArea else { return place.resolved.coordinate }
        return IncidentMapScale.northernRim(
            of: place.resolved.coordinate,
            radius: IncidentMapScale.postalAreaRadius
        )
    }

    // MARK: - What is drawn over the map

    /// The data's age, and what is still arriving.
    ///
    /// The age is here because the licence reason for showing it is about the *app* rather than
    /// about the list: the feed is provided "as is" and must not be presented as authoritative,
    /// and a map with circles on it reads as more authoritative than a table, not less. This tab
    /// has no list, so without this line it would be the one screen with no idea how old it is.
    ///
    /// **A line of text, not an element.** It was a full-width glass capsule at the top, which
    /// put a strip of the app's own chrome directly under the navigation bar — a second bar, in
    /// the one place a reader is already looking at bar. Then it was the same capsule at the
    /// bottom, which was the same mistake lower down. It is a caption, so it is drawn like one:
    /// no surface, bottom-trailing, above the tab bar, where a map keeps its small print.
    ///
    /// What that costs is legibility: text over a map has no surface holding it up. Small and
    /// `.secondary` is what Apple's own map attribution does, and it is enough over most of a
    /// map and not over all of one. If it proves unreadable, a shadow is the next thing to try
    /// rather than the box coming back.
    private var notice: some View {
        HStack(spacing: 6) {
            if feed.status.isStale {
                Image(systemName: "exclamationmark.triangle")
            }
            Text(feed.status.text)
            if pendingPlaces > 0 {
                Text("· Finding \(pendingPlaces) more…")
            }
        }
        .font(.caption2)
        .foregroundStyle(feed.status.isStale ? Color.orange : Color.secondary)
        .padding(.trailing, 12)
        .padding(.bottom, 10)
    }

    /// One place's card: every incident there, each a way into its own detail view.
    ///
    /// It can hold more than one row, which is the whole reason it is a card rather than a
    /// single line: two of the thirteen places in the live capture hold two incidents each.
    private func callout(for place: Place) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(place.incidents.count == 1 ? "1 incident" : "\(place.incidents.count) incidents")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)

                Spacer(minLength: 12)

                // Explicit rather than relying on a tap elsewhere in the map to clear the
                // selection: a control that dismisses is something a reader can look for.
                Button {
                    selected = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.secondary)
            }

            ForEach(place.incidents) { incident in
                NavigationLink {
                    IncidentDetailView(incident: incident)
                } label: {
                    row(for: incident)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: 280, alignment: .leading)
        .mapSurface(cornerRadius: 12)
    }

    /// One incident inside a place's card.
    ///
    /// The location is the same for every row here — that is what put them together — so the
    /// rows are told apart by their type and their dispatch time, which is why those are what
    /// the second line carries.
    private func row(for incident: Incident) -> some View {
        let location = CompactColumn.primeStreet.cell(for: incident, timeFormat: dispatchTimeFormat)
        let type = CompactColumn.incidentType.cell(for: incident, timeFormat: dispatchTimeFormat)
        let time = CompactColumn.dispatchTime.cell(for: incident, timeFormat: dispatchTimeFormat)

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(location.text ?? NotProvided.mark)
                    .font(.caption)
                    .fontWeight(.medium)
                if location.isFallback {
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                }
                if incident.warrantsAttention {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                }
            }
            .foregroundStyle(incident.warrantsAttention ? Color.orange : Color.primary)

            Text([type.text, time.text].compactMap { $0 }.joined(separator: " · "))
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview("Map — bare") {
    IncidentsMapPage(feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }))
}

// The same page in a navigation stack, to see what a default bar over it would do. The app
// ships neither of these exactly: `RootView` hides the bar on the map tab and floats the title
// and the controls instead, so the shipped shape is the bare one plus floating chrome — and the
// `RootView` preview shows it whole, header and all.
#Preview("Map — in a navigation stack") {
    NavigationStack {
        IncidentsMapPage(feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }))
    }
}
