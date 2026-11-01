import MapKit
import SwiftUI

/// One published point, on a small locator map.
///
/// The station page uses it: one ring dot, framed around the published coordinate, with no geocoder
/// and no boundary. The mark is the live map's dot rather than a teardrop pin, so the app has one
/// pin vocabulary. The division page uses an area map instead, because a division is ground.
struct ReferenceLocationMap: View {

    let title: String
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(
            initialPosition: .region(
                IncidentMapScale.region(around: coordinate, isArea: false)
            ),
            interactionModes: [.pan, .zoom]
        ) {
            Annotation(title, coordinate: coordinate) {
                CataloguePin()
            }
            .annotationTitles(.hidden)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }
}
