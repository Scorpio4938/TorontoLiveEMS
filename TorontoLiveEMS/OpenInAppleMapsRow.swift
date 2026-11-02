import CoreLocation
import MapKit
import SwiftUI
import TorontoLiveEMSKit

/// A plain row that hands one place to Apple Maps.
///
/// **Not a `Link`.** A bare `maps.apple.com` URL opens an unnamed point; `MKMapItem` carries the
/// point and its name, so the reader arrives at a named place rather than a spot on the map.
struct OpenInAppleMapsRow: View {

    let destination: AppleMapsDestination

    var body: some View {
        LocationActionRow(title: "Open in Apple Maps", action: open)
    }

    private func open() {
        // `MKPlacemark` and `MKMapItem(placemark:)` were deprecated at iOS 26. The modern
        // initializer takes a location and an optional postal address; this name is an
        // intersection or a street, not a postal address, so the address stays nil and the name
        // travels in the property Maps reads for the pin.
        let item = MKMapItem(
            location: CLLocation(
                latitude: destination.coordinate.latitude,
                longitude: destination.coordinate.longitude
            ),
            address: nil
        )
        item.name = destination.name
        _ = item.openInMaps(launchOptions: nil)
    }
}
