import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Numbers the two maps share.
///
/// In one place because they draw the same incidents: a shape that means a postal area on the
/// detail map has to mean the same thing on the general one, and a zoom that shows an incident
/// properly has to be the same zoom in both.
enum IncidentMapScale {

    /// How wide the **fallback** circle is for a postal area.
    ///
    /// **This is no longer how a postal area is drawn.** `PostalAreas` holds the real boundary —
    /// Statistics Canada's, generated into the package — and both maps draw that. What is left
    /// here is the one case the file cannot answer: a postal area created after the 2021 census,
    /// which no boundary file this app carries would know about. A worse answer beats no answer,
    /// and "nothing published means nothing drawn" is a rule about values the City withheld, not
    /// about a shape we failed to ship.
    static let postalAreaRadius: CLLocationDistance = 1_200

    /// Where the general map opens: the whole city, which is the whole feed.
    static let city = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.7180, longitude: -79.3780),
        span: MKCoordinateSpan(latitudeDelta: 0.32, longitudeDelta: 0.42)
    )

    /// Where the detail map opens for a published area: the area, with a margin around it.
    ///
    /// The margin is for the same reason the circle was backed off from — a boundary cropped by
    /// the frame reads as a shape that failed to load. The minimum span is for the small ones:
    /// M5C is a quarter of a square kilometre, and framing exactly that would zoom past any
    /// context worth having.
    static func region(for bounds: PostalAreas.Bounds) -> MKCoordinateRegion {
        let margin = 1.25
        return MKCoordinateRegion(
            center: bounds.centre.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: max(bounds.latitudeSpan * margin, 0.01),
                longitudeDelta: max(bounds.longitudeSpan * margin, 0.01)
            )
        )
    }

    /// Where the detail map opens, given one resolved location.
    ///
    /// Backed off for an area, so the fallback circle sits inside the frame rather than filling
    /// it — a circle cropped by the edges reads as a pin that failed to load.
    static func region(around coordinate: CLLocationCoordinate2D, isArea: Bool) -> MKCoordinateRegion {
        let span = isArea ? 0.045 : 0.010
        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    /// The point on a fallback circle's **northern rim**, which is where its callout hangs from.
    ///
    /// A callout has to be anchored to something, and the only point a circle offers is its
    /// centre — which is exactly the claim ADR-0004 refuses when it refuses a pin. Hanging the
    /// card off the rim instead keeps the circle meaning *somewhere in here* while still putting
    /// the card next to the thing that was touched.
    ///
    /// Metres to degrees of latitude, at 111,320 to the degree. The longitude is untouched,
    /// because the rim directly above the centre shares it and Mercator puts north up — so this
    /// is the top edge on screen as well as on the globe. Across 1,200 m the projection's own
    /// distortion is far below a pixel, and the anchor is a place to put a card rather than a
    /// position anything is measured against.
    ///
    /// A published area does not use this: its callout hangs from `PostalAreas.Bounds.northCentre`,
    /// which is the same idea for a shape that is not a circle.
    static func northernRim(
        of centre: CLLocationCoordinate2D,
        radius: CLLocationDistance
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: centre.latitude + radius / 111_320,
            longitude: centre.longitude
        )
    }
}

extension MapKind {

    /// The style this kind asks the map for.
    ///
    /// **The whole of the app's knowledge about turning a stored preference into a map**, in one
    /// place, next to the maps it applies to. The enum itself is in the package, because that is
    /// where the app's stored preferences live and where they can be tested; `MapStyle` is here
    /// because it is MapKit's and the package holds no MapKit at all.
    ///
    /// Every return is written `MapStyle.…` rather than bare, because this switch has cases named
    /// the same as MapKit's styles and a bare `.standard` would be a question rather than a lookup.
    var style: MapStyle {
        switch self {
        case .standard:
            return MapStyle.standard

        // `.hybrid`, deliberately, and not `.imagery`: imagery carries no labels at all, which is
        // a map with no street names on it. Looked at, and rejected in exactly those terms.
        case .satellite:
            return MapStyle.hybrid
        }
    }
}

extension PostalAreas.Point {

    /// The same point, in the type the maps draw with.
    ///
    /// The package deliberately holds no MapKit, so this translation lives in the app rather than
    /// in the data — one conversion, in one place, for both maps.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension PostalAreas.Area {

    /// This piece of a postal area as something a map can draw.
    ///
    /// **Holes travel with their ring.** `MapPolygon`'s coordinate initialiser takes a single
    /// ring, so a piece with a hole would be drawn solid and claim ground that is not part of the
    /// area. The `MKPolygon` initialiser takes interior polygons, and one Toronto FSA has one —
    /// which is rare, and is exactly why it would otherwise be overlooked.
    var mapShape: MapPolygon {
        let ring = outer.map(\.coordinate)
        guard !holes.isEmpty else { return MapPolygon(coordinates: ring) }

        let interiorRings = holes.map { hole -> MKPolygon in
            let coordinates = hole.map(\.coordinate)
            return MKPolygon(coordinates: coordinates, count: coordinates.count)
        }
        return MapPolygon(
            MKPolygon(
                coordinates: ring,
                count: ring.count,
                interiorPolygons: interiorRings
            )
        )
    }
}

/// One incident's location, on a map.
///
/// A pin when the feed named a place, the published area when it named a postal area, and nothing
/// at all when it named neither. See `IncidentLocation` for which is which and why.
struct IncidentLocationMap: View {

    let incident: Incident
    let geocoder: IncidentGeocoder

    private var location: IncidentLocation {
        IncidentLocation.from(incident)
    }

    /// The area the City named, when it named a postal area the boundary file knows.
    ///
    /// **No geocoder is asked for one of these.** The boundary file is in the bundle, so a postal
    /// incident costs no network at all — and the map shows the area the City actually published,
    /// rather than a circle around wherever Apple's geocoder happened to land.
    private var publishedArea: (pieces: [PostalAreas.Area], bounds: PostalAreas.Bounds)? {
        guard
            case .postalArea(let code) = location,
            let pieces = PostalAreas.bundled.areas(for: code),
            let bounds = PostalAreas.bundled.bounds(for: code)
        else {
            return nil
        }
        return (pieces, bounds)
    }

    var body: some View {
        Group {
            if location == .unpublished {
                // Not an empty frame. A blank map invites the reader to wonder what went wrong;
                // a sentence tells them what the feed did.
                Text("The City did not publish a location for this incident.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            } else if let publishedArea {
                areaMap(publishedArea.pieces, bounds: publishedArea.bounds)
            } else if let resolved = geocoder.known(location) {
                map(for: resolved)
            } else {
                // Resolving, or failed. Either way there is nothing to draw yet, and a spinner
                // that never stops would be worse than a map that arrives.
                HStack(spacing: 6) {
                    ProgressView()
                    Text("Finding this location…")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .task(id: incident.incidentNumber) {
            // Asked only for what the shapes cannot answer.
            guard publishedArea == nil else { return }
            await geocoder.resolve([location])
        }
    }

    /// The published area, drawn as the area it is.
    ///
    /// Every piece is drawn, not just the first: twenty of Toronto's FSAs are in more than one
    /// piece, and the Harbourfront one is twenty pieces on its own. Drawing the largest and
    /// calling it the area would be the same kind of claim as a pin.
    private func areaMap(_ pieces: [PostalAreas.Area], bounds: PostalAreas.Bounds) -> some View {
        // The incident's own urgency, on the same rule as its pin would be: red for the most
        // urgent, orange for the rest. An area is a mark like any other, and the orange it used to
        // be painted with said nothing about the incident inside it.
        let colour = MarkColour.of(warrantsAttention: incident.warrantsAttention)
        return Map(
            initialPosition: .region(IncidentMapScale.region(for: bounds)),
            interactionModes: [.pan, .zoom]
        ) {
            ForEach(pieces.indices, id: \.self) { index in
                pieces[index].mapShape
                    .foregroundStyle(colour.opacity(0.20))
                    .stroke(colour, lineWidth: 1)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }

    /// The map for everything the boundary file cannot answer: a precise address, or a postal area
    /// newer than the file.
    private func map(for resolved: IncidentGeocoder.Resolved) -> some View {
        let colour = MarkColour.of(warrantsAttention: incident.warrantsAttention)
        return Map(
            initialPosition: .region(
                IncidentMapScale.region(around: resolved.coordinate, isArea: resolved.isArea)
            ),
            interactionModes: [.pan, .zoom]
        ) {
            if resolved.isArea {
                MapCircle(center: resolved.coordinate, radius: IncidentMapScale.postalAreaRadius)
                    .foregroundStyle(colour.opacity(0.20))
                    .stroke(colour, lineWidth: 1)
            } else {
                Annotation(incident.incidentNumber, coordinate: resolved.coordinate) {
                    IncidentPin(warrantsAttention: incident.warrantsAttention)
                }
                .annotationTitles(.hidden)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }
}

/// The dot that stands for an incident on a map.
///
/// Red for the most urgent, orange for the rest — `MarkColour`, the same definition the table and
/// the areas use. A white ring because a coloured dot on a coloured map needs an edge that is not
/// the map's colour.
///
/// It is told *whether* rather than *which incident*, because a place can hold more than one and a
/// dot is one dot. The caller decides — and it decides from an `IncidentMark`, which is where that
/// judgement lives now, so that a mark on the large map and a dot here cannot come to disagree.
struct IncidentPin: View {

    let warrantsAttention: Bool

    var body: some View {
        Circle()
            .fill(MarkColour.of(warrantsAttention: warrantsAttention))
            .frame(width: 13, height: 13)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .shadow(radius: 1)
    }
}
