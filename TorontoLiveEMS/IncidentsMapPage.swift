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
/// **Every tap is ours.** The map's own selection is not used at all, and that is a finding
/// rather than a preference. It cannot select an overlay — tapping a polygon on a real build
/// produced "Failed to acquire drawable, rendering to temporary texture" and no card — and where
/// it *can* select, on an annotation, it raced this page's own gesture: a pin's card appeared and
/// was then wiped by whichever of the two answered last. So nothing on this map is tagged, a tap
/// is turned into a coordinate through `MapReader`, and it is tested against the published shapes
/// and the pins. One mechanism, one answer, and a tap that lands on nothing puts the card away.
struct IncidentsMapPage: View {

    let feed: IncidentFeed

    @State private var geocoder = IncidentGeocoder()
    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)
    @State private var selected: IncidentLocation?

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    /// What a place is drawn as.
    ///
    /// **The published area first, and the geocoder only for what it alone can answer.** A postal
    /// area needs no lookup now: the boundary file ships in the bundle, so a postal incident costs
    /// no network at all and the map shows the area the City published rather than a circle around
    /// wherever Apple's geocoder landed.
    private enum Mark {
        /// The area the City named, as the pieces it is made of.
        case area(pieces: [PostalAreas.Area], bounds: PostalAreas.Bounds)
        /// A postal area the boundary file does not know, drawn the way the app drew every one of
        /// them before: an approximation, but not nothing.
        case circle(centre: CLLocationCoordinate2D)
        /// A place the feed named precisely.
        case pin(CLLocationCoordinate2D)
    }

    /// A place the feed named, once, with however many incidents are there.
    private struct Place: Identifiable {
        let location: IncidentLocation
        let mark: Mark
        let incidents: [Incident]

        var id: IncidentLocation { location }

        /// Whether anything at this place warrants attention.
        ///
        /// A place takes the colour of its most serious incident, because a mark is one mark: two
        /// of the thirteen places in the live capture hold two incidents each, and a neighbourhood
        /// holding a fire must not be drawn as though it held only the medical call beside it.
        var isUrgent: Bool { incidents.contains(where: \.warrantsAttention) }
    }

    var body: some View {
        // `MapReader`, because a tap has to become a coordinate: the areas are hit-tested here
        // rather than selected by the map. See `place(at:in:)` for why.
        MapReader { proxy in
            Map(position: $position) {
                ForEach(places) { place in
                    // Red for the most urgent, orange for the rest — and the same for every kind of
                    // mark, so an area is coloured by what is in it rather than by being an area.
                    // The orange that used to be painted on every postal area was the shape's
                    // colour, which meant the map said "look here" about a quiet neighbourhood.
                    let colour = MarkColour.of(warrantsAttention: place.isUrgent)

                    if case .area(let pieces, _) = place.mark {
                        // The area the City named, drawn as the area it is. All of it: twenty of
                        // Toronto's FSAs are in more than one piece, and drawing the largest and
                        // calling it the area would be the same kind of claim as a pin.
                        //
                        // **Nothing here is tagged.** An overlay cannot be selected by a tap — a
                        // build proved it — and a tag on it only invites MapKit to try.
                        ForEach(pieces.indices, id: \.self) { index in
                            pieces[index].mapShape
                                .foregroundStyle(colour.opacity(0.20))
                                .stroke(colour, lineWidth: 1)
                        }
                    } else if case .circle(let centre) = place.mark {
                        // A postal area the boundary file does not know. Drawing it as a pin would
                        // put a medical incident at the centre of a neighbourhood and call it a
                        // location, which is the narrowing ADR-0004 forbids; a circle says
                        // *somewhere in here*.
                        MapCircle(center: centre, radius: IncidentMapScale.postalAreaRadius)
                            .foregroundStyle(colour.opacity(0.20))
                            .stroke(colour, lineWidth: 1)
                    } else if case .pin(let coordinate) = place.mark {
                        // **Untagged, and that is the fix for a card that flashed and went.** A tag
                        // here made MapKit select the pin on a tap while this page's own gesture was
                        // also running, so the two answers raced: the card appeared and was then
                        // wiped by whichever lost. One mechanism, one answer.
                        Annotation("", coordinate: coordinate) {
                            IncidentPin(warrantsAttention: place.isUrgent)
                        }
                        .annotationTitles(.hidden)
                    }
                }

                // The card, drawn inside the map so it needs no coordinate-to-point conversion —
                // and so it pans and zooms with the thing it belongs to. Anchored to the northern
                // edge for an area, never to its middle.
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
            // **Every tap is decided here, and only here.** The map's own selection is not used
            // at all: with it, a tap on a pin set the selection twice — once by MapKit and once by
            // this — and a card that flashed and vanished was the result. There is one mechanism
            // now, and one rule: a tap that lands on a place shows its card, and a tap that lands
            // on nothing puts the card away. The second half is the dismissal, which is why this
            // sets the selection whether or not something was hit.
            .onTapGesture(coordinateSpace: .local) { point in
                selected = place(at: point, in: proxy)?.location
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
    }

    // MARK: - What the feed gave us

    /// Every distinct place the feed named, in the order the incidents were published.
    ///
    /// Nothing is filtered by whether it can be **found** — a postal area with no boundary and a
    /// cross street are both questions worth asking. What is filtered, further down, is what
    /// needs asking at all.
    private var namedPlaces: [IncidentLocation] {
        var seen: [IncidentLocation] = []
        for incident in feed.snapshot?.incidents ?? [] {
            let location = IncidentLocation.from(incident)
            guard location != .unpublished, !seen.contains(location) else { continue }
            seen.append(location)
        }
        return seen
    }

    /// The places a geocoder has to be asked about.
    ///
    /// **A postal area the boundary file knows is not one of them.** Asking anyway would be a
    /// network round trip per postal incident for an answer the app then throws away, and it was
    /// the app's most obvious waste: on the live capture, nine of fifteen incidents are postal
    /// areas.
    private var lookedUp: [IncidentLocation] {
        namedPlaces.filter { publishedArea(for: $0) == nil }
    }

    /// The published boundary for a location, when the City named a postal area the file knows.
    private func publishedArea(
        for location: IncidentLocation
    ) -> (pieces: [PostalAreas.Area], bounds: PostalAreas.Bounds)? {
        guard
            case .postalArea(let code) = location,
            let pieces = PostalAreas.bundled.areas(for: code),
            let bounds = PostalAreas.bundled.bounds(for: code)
        else {
            return nil
        }
        return (pieces, bounds)
    }

    /// The places that can be drawn: a location, and something to draw for it.
    private var places: [Place] {
        let incidents = feed.snapshot?.incidents ?? []
        return namedPlaces.compactMap { location in
            let here = incidents.filter { IncidentLocation.from($0) == location }

            if let published = publishedArea(for: location) {
                return Place(
                    location: location,
                    mark: .area(pieces: published.pieces, bounds: published.bounds),
                    incidents: here
                )
            }
            guard let resolved = geocoder.known(location) else { return nil }
            return Place(
                location: location,
                mark: resolved.isArea
                    ? .circle(centre: resolved.coordinate)
                    : .pin(resolved.coordinate),
                incidents: here
            )
        }
    }

    private var selectedPlace: Place? {
        guard let selected else { return nil }
        return places.first { $0.location == selected }
    }

    /// Places still being looked up. Postal areas are not among them any more — they are answered
    /// from the bundle before anything is asked.
    private var pendingPlaces: Int {
        lookedUp.filter { geocoder.outcome(of: $0) == .pending }.count
    }

    /// Where a place's card hangs from: above a pin, above an area's northern edge, never a middle.
    ///
    /// For a published area that is the top of its own box, above the box's middle — the same
    /// place the fallback circle's northern rim gives, for a shape that is not a circle.
    private func anchor(for place: Place) -> CLLocationCoordinate2D {
        switch place.mark {
        case .area(_, let bounds):
            return bounds.northCentre.coordinate
        case .circle(let centre):
            return IncidentMapScale.northernRim(
                of: centre,
                radius: IncidentMapScale.postalAreaRadius
            )
        case .pin(let coordinate):
            return coordinate
        }
    }

    /// The place a tap landed on, if it landed on one.
    ///
    /// **Why this exists at all.** The map selects an annotation on a tap and does not select an
    /// overlay: tapping a polygon on a real build produced "Failed to acquire drawable, rendering
    /// to temporary texture" and no card at all. So nothing on this map is tagged, the map's
    /// selection is never used, and every tap is tested here.
    ///
    /// **Pins first, and generously.** A pin is a thirteen-point dot, so a tap within twenty-two
    /// points of one is taken to be that pin rather than the area behind it: a reader who hit a
    /// marker that small meant it, and an area is large enough that missing by a little costs
    /// nothing.
    ///
    /// Then the shapes. A published area is tested with `PostalAreas.contains`, which is the only
    /// authority on where the City's boundary puts a coordinate; the fallback circle has no shape
    /// to test, so it is tested with the same radius it is drawn at. Nil means the tap hit nothing,
    /// which is how the card is dismissed.
    ///
    /// **`.local`, on both sides.** `MapProxy.convert` is documented as being relative to the
    /// coordinate space associated with the `MapReader`, and the map fills that reader exactly, so
    /// the tap and the conversion are talking about the same space by construction rather than by
    /// agreement.
    private func place(at point: CGPoint, in proxy: MapProxy) -> Place? {
        for place in places {
            guard
                case .pin(let coordinate) = place.mark,
                let centre = proxy.convert(coordinate, to: .local)
            else { continue }
            if hypot(centre.x - point.x, centre.y - point.y) <= 22 {
                return place
            }
        }

        guard let coordinate = proxy.convert(point, from: .local) else { return nil }
        let tapped = PostalAreas.Point(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return places.first { place in
            switch place.mark {
            case .area(let pieces, _):
                return pieces.contains { PostalAreas.contains(tapped, in: $0) }
            case .circle(let centre):
                return CLLocation(latitude: centre.latitude, longitude: centre.longitude)
                    .distance(
                        from: CLLocation(
                            latitude: tapped.latitude,
                            longitude: tapped.longitude
                        )
                    ) <= IncidentMapScale.postalAreaRadius
            case .pin:
                return false
            }
        }
    }

    // MARK: - What is drawn over the map

    /// The data's age, and what is still arriving.
    ///
    /// The age is here because the licence reason for showing it is about the *app* rather than
    /// about the list: the feed is provided "as is" and must not be presented as authoritative,
    /// and a map with the City's own shapes on it reads as more authoritative than a table, not
    /// less. This tab has no list, so without this line it would be the one screen with no idea
    /// how old it is.
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
    /// single line: two of the thirteen places in the live capture hold two incidents each. The
    /// rows say how many there are, which is why nothing above them counts them.
    ///
    /// **No close button, and no heading.** It carried "2 incidents" and an `xmark` beside it,
    /// which cost a whole row of height to say what the rows below already said, and to offer a
    /// way out that tapping the map already is. Reported from a phone: the card was too tall for
    /// what it held, and a dismiss control is not what a thumb reaches for when tapping elsewhere
    /// is the gesture it is already making.
    private func callout(for place: Place) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(place.incidents) { incident in
                NavigationLink {
                    IncidentDetailView(incident: incident)
                } label: {
                    row(for: incident)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(maxWidth: 260, alignment: .leading)
        .glassSurface(cornerRadius: 12)
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
            .foregroundStyle(incident.warrantsAttention ? MarkColour.urgent : Color.primary)

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
