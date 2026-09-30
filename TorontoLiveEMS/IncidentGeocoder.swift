import MapKit
import Observation
import TorontoLiveEMSKit

/// Turns what the feed published about a location into a coordinate, once.
///
/// **One request at a time, and every answer kept.** Apple's geocoder takes a single address
/// string, so thirty-five incidents means thirty-five requests, against a service with
/// undisclosed rate limits and no batch form. The cache is not an optimisation here; it is what
/// stops a refresh from asking the same questions again.
///
/// Failures are remembered too. A location that does not resolve will not resolve next time
/// either, and retrying it on every refresh is how an app gets throttled.
///
/// `MKGeocodingRequest` rather than `CLGeocoder`, which Apple deprecated at iOS 26 with the note
/// "Use MapKit". Checked in Apple's documentation rather than guessed.
@MainActor
@Observable
final class IncidentGeocoder {

    /// A resolved location: where it is, and whether it is a point or an extent.
    struct Resolved: Equatable {
        let latitude: Double
        let longitude: Double
        let isArea: Bool

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    private var resolved: [IncidentLocation: Resolved] = [:]
    private var settled: Set<IncidentLocation> = []
    private var isResolving = false

    /// What is already known, if anything. Never triggers a lookup — a view that asked for one
    /// while drawing would ask again on every redraw.
    func known(_ location: IncidentLocation) -> Resolved? {
        resolved[location]
    }

    /// Looks up everything not already settled, one at a time.
    ///
    /// Serial rather than concurrent: the requests are to the same service on the same terms, and
    /// issuing thirty-five at once is the behaviour limits exist for.
    func resolve(_ locations: [IncidentLocation]) async {
        guard !isResolving else {
            return
        }
        isResolving = true
        defer { isResolving = false }

        for location in locations where !settled.contains(location) {
            settled.insert(location)
            guard location.query != nil else {
                continue
            }

            guard let request = MKGeocodingRequest(addressString: location.query!) else {
                continue
            }
            do {
                let items = try await request.mapItems
                guard let item = items.first else {
                    continue
                }
                // `location`, not `placemark`: the latter is the accessor on its way out.
                let coordinate = item.location.coordinate
                resolved[location] = Resolved(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    isArea: location.isArea
                )
            } catch {
                // Left unresolved and left settled. The failure is the answer.
                continue
            }
        }
    }
}
