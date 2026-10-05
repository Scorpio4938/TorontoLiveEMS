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

    /// The police calls, drawn from the same kind of mark as the fire incidents.
    ///
    /// **A required parameter rather than a defaulted one.** `PoliceCallFeed` is `@MainActor`, and a
    /// default argument is evaluated outside the actor — which is the trap this project has already
    /// been caught by once. The previews and `RootView` pass it in like everything else.
    let policeFeed: PoliceCallFeed

    @State private var geocoder = IncidentGeocoder()
    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)

    /// The place whose card is showing, by `Place.id` rather than by location: a police place is a
    /// coordinate and has no `IncidentLocation` to be named by.
    @State private var selected: String?

    @AppStorage(SettingsKey.dispatchTimeFormat)
    private var dispatchTimeFormat: DispatchTimeFormat = .twelveHour

    /// Which kind of map to draw.
    ///
    /// The same stored key the chrome's control writes, which is how a control in one view changes
    /// a map in another without either of them knowing the other exists.
    @AppStorage(SettingsKey.mapKind)
    private var mapKind: MapKind = .standard

    /// Which feeds to draw. The same stored key the chrome's control writes, which is how a control in
    /// one view changes a map in another without either knowing the other exists.
    @AppStorage(SettingsKey.mapFilter)
    private var mapFilter: MapFilter = .all

    /// The same stored key the police page reads, so a reader who chose codes sees codes here too.
    @AppStorage(SettingsKey.policeCallTypeStyle)
    private var policeCallTypeStyle: PoliceCallTypeStyle = .words

    /// What a place is drawn as.
    ///
    /// **Geometry, not identity.** This says what shape the *published location* justifies — the
    /// City's boundary, a circle where there is none, or a point the feed named — which is a fact
    /// about the place. What kind of incident it is, and whether it warrants attention, is
    /// `IncidentMark`'s business and now arrives separately. The two used to be one value, which is
    /// how a page came to hold a private copy of the app's colour rule.
    ///
    /// **The published area first, and the geocoder only for what it alone can answer.** A postal
    /// area needs no lookup now: the boundary file ships in the bundle, so a postal incident costs
    /// no network at all and the map shows the area the City published rather than a circle around
    /// wherever Apple's geocoder landed.
    private enum Geometry {
        /// The area the City named, as the pieces it is made of.
        case area(pieces: [PostalAreas.Area], bounds: PostalAreas.Bounds)
        /// A postal area the boundary file does not know, drawn the way the app drew every one of
        /// them before: an approximation, but not nothing.
        case circle(centre: CLLocationCoordinate2D)
        /// A place the feed named precisely.
        case pin(CLLocationCoordinate2D)
    }

    /// A place the feed named, once, with however many records are there.
    ///
    /// **One type for both feeds, which is what makes the drawing one path.** Its `geometry` and its
    /// `mark` are what the map needs, and both are the same kind of thing whoever published them. What
    /// differs is the records inside it, and only the card looks at those.
    private struct Place: Identifiable {

        /// Stable across reads, and unique across sources: a fire place is named by its location, a
        /// police place by its coordinate. Prefixed by source so the two can never collide.
        let id: String

        let geometry: Geometry

        /// What the place is drawn as: its kind and its colour, from its most serious record.
        ///
        /// **A place takes one record's mark, because a mark is one mark.** Two of the thirteen fire
        /// places in the live capture hold two incidents each, and a neighbourhood holding a fire must
        /// not be drawn as though it held only the medical call beside it. The mark is built by
        /// `IncidentMark`, which is the one place that knows what a kind or an urgency is; this page
        /// reads neither, which is what lets a second feed arrive without a second way of drawing.
        let mark: IncidentMark

        let contents: Contents

        /// What is at the place: records of one feed or the other, never both.
        ///
        /// An enum rather than two optional arrays, so that "this place has no incidents and no calls"
        /// is not a state that can be written down.
        enum Contents {
            case fire([Incident])
            case police([PoliceCall])
        }
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
                    let colour = MarkColour.of(place.mark.urgency)

                    if case .area(let pieces, _) = place.geometry {
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
                    } else if case .circle(let centre) = place.geometry {
                        // A postal area the boundary file does not know. Drawing it as a pin would
                        // put a medical incident at the centre of a neighbourhood and call it a
                        // location, which is the narrowing ADR-0004 forbids; a circle says
                        // *somewhere in here*.
                        MapCircle(center: centre, radius: IncidentMapScale.postalAreaRadius)
                            .foregroundStyle(colour.opacity(0.20))
                            .stroke(colour, lineWidth: 1)
                    } else if case .pin(let coordinate) = place.geometry {
                        // **Untagged, and that is the fix for a card that flashed and went.** A tag
                        // here made MapKit select the pin on a tap while this page's own gesture was
                        // also running, so the two answers raced: the card appeared and was then
                        // wiped by whichever lost. One mechanism, one answer.
                        Annotation("", coordinate: coordinate) {
                            MapPin(mark: place.mark)
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
            // The kind the reader chose, which is `.standard` unless they said otherwise. Nothing
            // on this page changes it: the control that does lives in the chrome above.
            .mapStyle(mapKind.style)
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
                selected = place(at: point, in: proxy)?.id
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
            // The police calls are read by this page too, when it arrives rather than at launch, for
            // the reason the police page reads them that way: nothing else on this tab needs them.
            .task {
                if policeFeed.calls == nil {
                    await policeFeed.load()
                }
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

    /// Everything on the map, from both feeds — minus whatever the reader has filtered out.
    ///
    /// The filter is applied here rather than inside the two lists, so that "which feeds" is one
    /// question in one place. It asks each mark where it came from and nothing else, which is what
    /// `MapFilter.keeps` is.
    private var places: [Place] {
        (firePlaces + policePlaces).filter { mapFilter.keeps($0.mark) }
    }

    /// The fire places that can be drawn: a location, something to draw for it, and its mark.
    private var firePlaces: [Place] {
        let incidents = feed.snapshot?.incidents ?? []
        return namedPlaces.compactMap { location in
            let here = incidents.filter { IncidentLocation.from($0) == location }
            // The mark first, because a place with no incidents at it is not a place. It cannot happen
            // — `namedPlaces` is built from these same incidents — and it is checked rather than
            // asserted, so that if it ever did, a mark would be missing rather than wrong.
            guard let mark = mostSeriousMark(among: here) else { return nil }

            let contents = Place.Contents.fire(here)
            if let published = publishedArea(for: location) {
                return Place(
                    id: Self.fireId(location),
                    geometry: .area(pieces: published.pieces, bounds: published.bounds),
                    mark: mark,
                    contents: contents
                )
            }
            guard let resolved = geocoder.known(location) else { return nil }
            return Place(
                id: Self.fireId(location),
                geometry: resolved.isArea
                    ? .circle(centre: resolved.coordinate)
                    : .pin(resolved.coordinate),
                mark: mark,
                contents: contents
            )
        }
    }

    /// A fire place's identity, prefixed so it can never collide with a police one.
    ///
    /// Through `description` rather than a hash: this is compared between renders, and `hashValue`
    /// changes from one launch to the next while the printed value does not.
    private static func fireId(_ location: IncidentLocation) -> String {
        "fire.\(String(describing: location))"
    }

    /// The police places: one mark per distinct point.
    ///
    /// **Grouped, by the same rule the fire places use, because a mark is one mark.** The Service
    /// publishes a point per call, and calls are not evenly spread: in the window sampled on
    /// 2026-10-05, eighty-nine calls sat at eighty-two distinct points, seven of them sharing a point
    /// with another call. Drawing those as two pins would stack two marks and leave one of them
    /// unreachable while the map claimed to show both.
    ///
    /// **Rounded to five decimal places — about a metre.** Two calls at one intersection are published
    /// with coordinates differing in the sixth place, so matching exactly would draw two pins a hand's
    /// width apart. Five places is the grain the coincidences were found at, and is far finer than any
    /// pin is wide.
    private var policePlaces: [Place] {
        var byPoint: [PointKey: [PoliceCall]] = [:]
        var order: [PointKey] = []
        for call in policeFeed.calls ?? [] {
            let key = PointKey(call)
            if byPoint[key] == nil {
                order.append(key)
            }
            byPoint[key, default: []].append(call)
        }

        return order.compactMap { key in
            guard let calls = byPoint[key], let first = calls.first else { return nil }
            return Place(
                id: "police.\(key.id)",
                geometry: .pin(
                    CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
                ),
                mark: IncidentMark(call: first),
                contents: .police(calls)
            )
        }
    }

    /// A point, at the grain two calls have to agree on to be the same place.
    private struct PointKey: Hashable {
        let latitude: Int
        let longitude: Int

        var id: String { "\(latitude),\(longitude)" }

        init(_ call: PoliceCall) {
            latitude = Int((call.latitude * 100_000).rounded())
            longitude = Int((call.longitude * 100_000).rounded())
        }
    }

    /// The mark a place wears: its most serious incident's.
    ///
    /// The most serious of them, by `Urgency.rank`. A place with one record has one answer, and a
    /// place with two has the more serious of the two — the judgement this page made about colour
    /// before it had marks at all, now made against the severity rather than against a flag.
    private func mostSeriousMark(among incidents: [Incident]) -> IncidentMark? {
        let marks = incidents.map(IncidentMark.init(incident:))
        return marks.min { $0.urgency.rank < $1.urgency.rank }
    }

    private var selectedPlace: Place? {
        guard let selected else { return nil }
        return places.first { $0.id == selected }
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
        switch place.geometry {
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
                case .pin(let coordinate) = place.geometry,
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
            switch place.geometry {
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
            if isStale {
                Image(systemName: "exclamationmark.triangle")
            }
            Text(noticeText)
            // A filtered map with nothing on screen to say so is the confusion this prevents: half the
            // marks gone and no reason visible. Only when a filter is in force, because "Both Feeds" is
            // not worth saying.
            if mapFilter != .all {
                Text("· \(mapFilter.label)")
            }
            if pendingPlaces > 0 {
                Text("· Finding \(pendingPlaces) more…")
            }
        }
        .font(.caption2)
        .foregroundStyle(isStale ? Color.orange : Color.secondary)
        .padding(.trailing, 12)
        .padding(.bottom, 10)
    }

    /// The line the map carries: whose data this is, and how old it is.
    ///
    /// **"City/TPS", where the fire feed's own sentence says "City".** That sentence is shown on the
    /// fire page and in the fire table, where "City" is exactly right because there is nothing else
    /// on screen. This map draws both feeds, so the line has to name both — and it is written here
    /// rather than by changing `IncidentFeed`, which would have relabelled the fire page's line as
    /// well and made it say something untrue about a screen that holds no police data at all.
    ///
    /// **The time beside it is still the City's own tick**, which is the only republish time this
    /// page reads. The police feed states its own and the map does not yet show it; naming both
    /// sources while quoting one clock is the honest half of that, and a second time is what the line
    /// still needs before it is exact.
    private var noticeText: String {
        let updated = feed.snapshot?.updatedFromDatabaseAt ?? "an unknown time"
        return "City/TPS data as of \(updated)"
    }

    /// Whether anything on the map is known to be out of date.
    ///
    /// Either feed being stale is enough: the line describes the map, and a map with one old feed on
    /// it is a map showing something old, whichever side it came from.
    private var isStale: Bool {
        feed.status.isStale || policeFeed.isShowingStaleResult
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
            switch place.contents {
            case .fire(let incidents):
                ForEach(incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident)
                    } label: {
                        row(for: incident)
                    }
                    .buttonStyle(.plain)
                }
            case .police(let calls):
                ForEach(calls) { call in
                    NavigationLink {
                        PoliceCallDetailView(call: call)
                    } label: {
                        policeRow(for: call)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: 260, alignment: .leading)
        .glassSurface(cornerRadius: 12)
    }

    /// One police call inside a place's card.
    ///
    /// The point is the same for every row here — that is what put them together — so the rows are
    /// told apart by what the call was and when, which is what the compact columns say everywhere else
    /// in the app, and which reads the reader's own choice of words or code.
    private func policeRow(for call: PoliceCall) -> some View {
        let type = CompactColumn<PoliceCall>
            .callType(style: policeCallTypeStyle)
            .cell(call, dispatchTimeFormat)
        let time = CompactColumn<PoliceCall>.occurrenceTime.cell(call, dispatchTimeFormat)

        return VStack(alignment: .leading, spacing: 2) {
            Text(type.text ?? NotProvided.mark)
                .font(.caption)
                .fontWeight(.medium)
            Text(time.text ?? NotProvided.mark)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// One incident inside a place's card.
    ///
    /// The location is the same for every row here — that is what put them together — so the
    /// rows are told apart by their type and their dispatch time, which is why those are what
    /// the second line carries.
    private func row(for incident: Incident) -> some View {
        let location = CompactColumn<Incident>.primeStreet.cell(incident, dispatchTimeFormat)
        let type = CompactColumn<Incident>.incidentType.cell(incident, dispatchTimeFormat)
        let time = CompactColumn<Incident>.dispatchTime.cell(incident, dispatchTimeFormat)
        // Through the mark rather than through the incident's own rule, so that what a row looks like
        // and what a mark on the map looks like cannot drift apart: there is one answer to "does this
        // warrant attention", and it is the mark's.
        let mark = IncidentMark(incident: incident)
        // Critical and nothing else: this is a line of text in a card, and the two-step question is
        // the right one for a row — the same one the table's tint asks.
        let isCritical = mark.urgency == .critical

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(location.text ?? NotProvided.mark)
                    .font(.caption)
                    .fontWeight(.medium)
                if location.isFallback {
                    Image(systemName: "arrow.left.and.right")
                        .font(.caption2)
                }
                if isCritical {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                }
            }
            .foregroundStyle(isCritical ? MarkColour.critical : Color.primary)

            Text([type.text, time.text].compactMap { $0 }.joined(separator: " · "))
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// One mark on the map: the kind's symbol, in the colour the state calls for.
///
/// **One view for both feeds.** A fire incident and a police call now differ in what their symbol says
/// and in nothing else about how they are drawn, which is the point of a mark: the map draws marks, and
/// a mark from a second publisher is the same kind of thing as one from the first. It replaces a pin
/// that was a bare coloured dot — the one thing a dot cannot do is say what it is.
///
/// The disc is white, which is the convention `IncidentPin` already uses for the ring around a dot:
/// a coloured mark on a coloured map needs an edge that is not the map's colour, and white reads over
/// a satellite map and a light one alike. It is written as `Color.white` rather than as a bare
/// `.background` style, because a bare `.background` in this position resolves to `View.background(_:)`
/// — a method, not a style — and the compiler says so rather than drawing something else.
///
/// The **shape** carries the kind and the **colour** carries whether the incident warrants attention;
/// neither is asked to do both jobs, which is the rule the fire side already recorded and the reason
/// the two live in different places.
private struct MapPin: View {

    let mark: IncidentMark

    @Environment(\.colorScheme) private var colourScheme

    private var colour: Color {
        MarkColour.of(mark.urgency)
    }

    /// The surface the glyph sits on.
    ///
    /// **It has to follow the appearance, and it did not.** `MarkColour.routine` — the tone most marks
    /// wear, by design — is `Color.secondary`, which is a *dark* grey in light mode and a *light* grey in
    /// dark mode. On a disc that was always white, every ordinary mark became a pale glyph on a white
    /// disc after dark: the map looked empty at night, with only the reds and oranges left visible, and
    /// grey rings around nothing.
    ///
    /// Two explicit colours rather than the system's own background, which is the spelling one would
    /// reach for first: that initialiser takes a UIKit colour, and this target builds for macOS as well
    /// as iOS. A pair chosen here is dull and portable, where a cleverer spelling would be neither.
    ///
    /// The ring does the other half of the work: a dark disc on a dark map is still findable, because
    /// the ring is the tone rather than the disc.
    private var disc: Color {
        colourScheme == .dark ? Color(white: 0.12) : Color.white
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(disc)
                .frame(width: 22, height: 22)
            Image(systemName: mark.category.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(colour)
        }
        .overlay(Circle().stroke(colour, lineWidth: 1.5))
        .shadow(radius: 1)
    }
}

/// The map's own legend: what a symbol means, and what a colour means.
///
/// **Reached from the chrome's info button on the map tab**, which used to open the fire feed's data
/// screen — a page about a feed that is only half of what this map draws.
///
/// **Rendered from the tables, never from a copy of them.** The symbols come from
/// `IncidentMark.Category`, the colours from `MarkColour` through `IncidentMark.Urgency`, and the
/// police codes in each severity are *looked up* — the documented list filtered by what the code table
/// says each one is. A legend that restates a mapping is a legend that can come to disagree with it,
/// which is the failure the fire screen's own note about its apparatus legend was written to avoid.
struct MapInformationContent: View {

    var body: some View {
        List {
            Section {
                Text("Both feeds on one map: the City's fire incidents as the areas and points it publishes, and the Service's police calls as the points it publishes. Every mark is a symbol for what kind of incident it is, in a colour for how much it matters.")
            } header: {
                Text("The Map")
            }

            Section {
                ForEach(IncidentMark.Category.allCases, id: \.self) { kind in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Image(systemName: kind.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.label)
                            Text(kind.note)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            } header: {
                Text("Symbols")
            } footer: {
                Text("The symbol says what kind of incident it is, and the nine are shared by both feeds — which is why a fire alarm and a police call about a fire wear the same bell. A call this app has no kind for is drawn as a question mark.")
            }

            Section {
                ForEach(IncidentMark.Urgency.allCases, id: \.self) { urgency in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Circle()
                            .fill(MarkColour.of(urgency))
                            .frame(width: 14, height: 14)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(urgency.label)
                            Text(urgency.fireRule)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            let codes = PoliceCallType.documented
                                .filter { IncidentMark.Urgency(callTypeCode: $0.code) == urgency }
                                .map(\.code)
                            if !codes.isEmpty {
                                Text("Police: " + codes.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Colours")
            } footer: {
                Text("The colour says how much an incident matters, and never what kind it is. Grey is most of the map on purpose: a colour that marks exceptions has to leave the majority quiet, or it marks nothing.\n\nThe fire severities are the City's own — a dangerous kind of call, or a response of ten or more vehicles. The police severities are this app's inference from the call type, because the Service publishes none and nothing in a call says how serious it is. A police code this app has not met yet is Unknown as well.")
            }
        }
        .navigationTitle("About the Map")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// The same screen, presented rather than pushed, for the reason the fire one is: a sheet needs a way
/// out of its own, and a pushed screen takes it from the navigation bar.
struct MapInformationView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MapInformationContent()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview("Map — bare") {
    IncidentsMapPage(
        feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }),
        policeFeed: PreviewCalls.feed()
    )
}

// The same page in a navigation stack, to see what a default bar over it would do. The app
// ships neither of these exactly: `RootView` hides the bar on the map tab and floats the title
// and the controls instead, so the shipped shape is the bare one plus floating chrome — and the
// `RootView` preview shows it whole, header and all.
#Preview("Map — in a navigation stack") {
    NavigationStack {
        IncidentsMapPage(
            feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }),
            policeFeed: PreviewCalls.feed()
        )
    }
}
