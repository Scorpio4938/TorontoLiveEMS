import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// Every active incident, on one map.
///
/// The same incidents as the list, from the same model — a map that fetched on its own could
/// disagree with the list about what is happening, which is a thing a reader would never think to
/// check.
///
/// Pins fill in as they resolve. Apple's geocoder takes one address string at a time against a
/// service with undisclosed limits, so thirty-five incidents arrive over some seconds rather than
/// at once; showing what is known and continuing is better than an empty map that becomes
/// populated all at once.
struct IncidentsMap: View {

    let model: IncidentFeedModel
    let geocoder: IncidentGeocoder

    @State private var position: MapCameraPosition = .region(IncidentMapScale.city)

    /// The incidents whose locations are already known, which is what the map draws.
    private var placed: [(incident: Incident, resolved: IncidentGeocoder.Resolved)] {
        model.incidents.compactMap { incident in
            guard let resolved = geocoder.known(IncidentLocation.from(incident)) else {
                return nil
            }
            return (incident, resolved)
        }
    }

    var body: some View {
        Map(position: $position) {
            ForEach(placed, id: \.incident.incidentNumber) { entry in
                if entry.resolved.isArea {
                    // A postal area. Drawing it as a pin would put a medical incident at the
                    // centre of a neighbourhood and call it a location — ADR-0004 forbids
                    // narrowing it, and this is the map's version of not narrowing it.
                    MapCircle(
                        center: entry.resolved.coordinate,
                        radius: IncidentMapScale.postalAreaRadius
                    )
                    .foregroundStyle(Color.orange.opacity(0.20))
                    .stroke(Color.orange, lineWidth: 1)
                } else {
                    Annotation(entry.incident.incidentNumber, coordinate: entry.resolved.coordinate) {
                        IncidentPin(incident: entry.incident)
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapControls {
            MapCompass()
            // `alignment` given rather than left off. `MapScaleView` has two initialisers and
            // every parameter of both has a default, so a bare `MapScaleView()` is ambiguous
            // between them — it reads as the natural call and is not one.
            MapScaleView(alignment: .leading)
        }
        .overlay(alignment: .top) {
            resolvingNotice
        }
        // Keyed on the incidents so a new set of them is looked up, and the same set is not.
        .task(id: model.incidents.map(\.incidentNumber)) {
            await geocoder.resolve(model.incidents.map(IncidentLocation.from))
        }
    }

    /// How many are still being looked up, and how many have nowhere to go.
    ///
    /// Worth saying out loud: with postal areas drawn as circles and some incidents carrying no
    /// location at all, a reader counting dots and comparing them to the list would otherwise
    /// find a discrepancy and no explanation.
    @ViewBuilder
    private var resolvingNotice: some View {
        let unresolved = model.incidents.count - placed.count
        if unresolved > 0 {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Finding \(unresolved) more…")
            }
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .padding(.top, 8)
        }
    }
}
