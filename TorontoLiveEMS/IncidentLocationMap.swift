import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Numbers the two maps share.
///
/// In one place because they draw the same incidents: a circle that means a postal area on the
/// detail map has to mean the same thing on the general one, and a zoom that shows an incident
/// properly has to be the same zoom in both.
enum IncidentMapScale {

    /// How wide the circle is for a postal area.
    ///
    /// **An approximation of an area, not a measurement of one.** An FSA is a neighbourhood and
    /// the City does not publish its boundary; a geocoder answers with a point somewhere inside
    /// it. This is the radius that reads as *somewhere in here* rather than as *here*, which is
    /// the whole reason it is a circle and not a pin.
    static let postalAreaRadius: CLLocationDistance = 1_200

    /// Where the general map opens: the whole city, which is the whole feed.
    static let city = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.7180, longitude: -79.3780),
        span: MKCoordinateSpan(latitudeDelta: 0.32, longitudeDelta: 0.42)
    )

    /// Where the detail map opens, given one resolved location.
    ///
    /// Backed off for an area, so the circle sits inside the frame rather than filling it — a
    /// circle cropped by the edges reads as a pin that failed to load.
    static func region(around coordinate: CLLocationCoordinate2D, isArea: Bool) -> MKCoordinateRegion {
        let span = isArea ? 0.045 : 0.010
        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    /// The point on an area's **northern rim**, which is where its callout hangs from.
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

/// One incident's location, on a map.
///
/// A pin when the feed named a place, a circle when it named an area, and nothing at all when it
/// named neither. See `IncidentLocation` for which is which and why.
struct IncidentLocationMap: View {

    let incident: Incident
    let geocoder: IncidentGeocoder

    private var location: IncidentLocation {
        IncidentLocation.from(incident)
    }

    var body: some View {
        Group {
            if location == .unpublished {
                // Not an empty frame. A blank map invites the reader to wonder what went wrong;
                // a sentence tells them what the feed did.
                Text("The City did not publish a location for this incident.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
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
            await geocoder.resolve([location])
        }
    }

    private func map(for resolved: IncidentGeocoder.Resolved) -> some View {
        Map(
            initialPosition: .region(
                IncidentMapScale.region(around: resolved.coordinate, isArea: resolved.isArea)
            ),
            interactionModes: [.pan, .zoom]
        ) {
            if resolved.isArea {
                MapCircle(center: resolved.coordinate, radius: IncidentMapScale.postalAreaRadius)
                    .foregroundStyle(Color.orange.opacity(0.20))
                    .stroke(Color.orange, lineWidth: 1)
            } else {
                Annotation(incident.incidentNumber, coordinate: resolved.coordinate) {
                    IncidentPin(incident: incident)
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
/// Orange for the incidents the app marks, and the accent otherwise — the same rule the list
/// uses, from the same place. A white ring because a coloured dot on a coloured map needs an
/// edge that is not the map's colour.
struct IncidentPin: View {

    let incident: Incident

    var body: some View {
        Circle()
            .fill(incident.warrantsAttention ? Color.orange : Color.accentColor)
            .frame(width: 13, height: 13)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .shadow(radius: 1)
    }
}
