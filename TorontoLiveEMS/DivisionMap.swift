import MapKit
import SwiftUI
import TorontoLiveEMSKit

extension PoliceDivision.Point {

    /// The same point, in the type the maps draw with.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension PoliceDivision.Area {

    /// This piece of a division as something a map can draw.
    ///
    /// Holes travel with the ring, for the same reason they do on a postal area: a piece with a hole
    /// drawn solid would claim ground the City did not put in the division.
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

extension IncidentMapScale {

    /// Where a division's area map opens: the division, with a margin around it.
    static func region(for bounds: PoliceDivision.Bounds) -> MKCoordinateRegion {
        let margin = 1.25
        return MKCoordinateRegion(
            center: bounds.centre.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: max(bounds.latitudeSpan * margin, 0.02),
                longitudeDelta: max(bounds.longitudeSpan * margin, 0.02)
            )
        )
    }
}

/// One division's published area, on a small map.
///
/// A division is ground, so this draws the City's boundary and nothing at its centre. The facility
/// address above the map is a separate published fact; a pin for it would be the one thing on a
/// division page that suggested the division is a point.
struct DivisionAreaMap: View {

    let division: PoliceDivision

    @AppStorage(SettingsKey.mapKind)
    private var mapKind: MapKind = .standard

    private var initialPosition: MapCameraPosition {
        guard let bounds = division.bounds else {
            return .region(IncidentMapScale.city)
        }
        return .region(IncidentMapScale.region(for: bounds))
    }

    var body: some View {
        Map(
            initialPosition: initialPosition,
            interactionModes: [.pan, .zoom]
        ) {
            ForEach(division.areas.indices, id: \.self) { index in
                division.areas[index].mapShape
                    .foregroundStyle(Color.secondary.opacity(0.20))
                    .stroke(Color.secondary, lineWidth: 1)
            }
        }
        .mapStyle(mapKind.style)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }
}

/// The Divisions catalogue as areas, with the live map's tap rule and card.
///
/// **No pins.** Every one of the 16 current divisions has a published boundary, so the map draws
/// the shape
/// the City drew. A tap inside a shape selects that division; a tap on empty ground puts the card
/// away. The card hangs from the northern edge of the selected area, never from its middle, and the
/// card opens the division page.
struct DivisionCatalogueMap: View {

    let divisions: [PoliceDivision]
    let policeFeed: PoliceCallFeed

    /// The camera and card, held by the catalogue so flipping to the list and back keeps the place.
    @Binding var position: MapCameraPosition
    @Binding var selected: String?

    @AppStorage(SettingsKey.mapKind)
    private var mapKind: MapKind = .standard

    private var selectedDivision: PoliceDivision? {
        guard let selected = selected else { return nil }
        return divisions.first { $0.number == selected }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                ForEach(divisions) { division in
                    ForEach(division.areas.indices, id: \.self) { index in
                        division.areas[index].mapShape
                            .foregroundStyle(Color.secondary.opacity(0.20))
                            .stroke(Color.secondary, lineWidth: 1)
                    }
                }

                if let selectedDivision = selectedDivision {
                    Annotation(
                        "",
                        coordinate: selectedDivision.bounds?.northCentre.coordinate
                            ?? IncidentMapScale.city.center,
                        anchor: .bottom
                    ) {
                        NavigationLink {
                            DivisionPage(division: selectedDivision, policeFeed: policeFeed)
                        } label: {
                            ReferenceMapCard(
                                title: selectedDivision.feedCode,
                                subtitle: subtitle(for: selectedDivision)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(mapKind.style)
            // The bar is gone in map mode, so the map runs to the top edge; keep the platform's
            // compass out of the floating chrome's band. Same rule as the live map.
            .mapCompassPadding()
            .onTapGesture(coordinateSpace: .global) { point in
                selected = division(at: point, in: proxy)?.number
            }
        }
    }

    private func subtitle(for division: PoliceDivision) -> String {
        PoliceFacilities.bundled.facility(forPublished: division.number)?.address
            ?? "Police division"
    }

    /// The division whose area contains the tap, or `nil` for empty ground.
    private func division(at point: CGPoint, in proxy: MapProxy) -> PoliceDivision? {
        guard let coordinate = proxy.convert(point, from: .global) else { return nil }
        let tapped = PoliceDivision.Point(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return divisions.first { division in
            division.areas.contains { PoliceDivision.contains(tapped, in: $0) }
        }
    }
}
