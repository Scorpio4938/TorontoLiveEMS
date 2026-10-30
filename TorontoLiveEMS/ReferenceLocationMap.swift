import MapKit
import SwiftUI

/// One published point, on a small locator map.
///
/// The station page and the division page both need the same map: one pin, framed around the
/// published coordinate, with no geocoder and no boundary. One view because two pages showing the
/// same fact should not be able to frame it two different ways.
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
            Marker(title, coordinate: coordinate)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .listRowInsets(EdgeInsets())
    }
}
