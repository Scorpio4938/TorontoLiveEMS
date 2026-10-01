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
/// **An answer is remembered. A failure is not.** Those were the same thing until the map was
/// empty and nothing said why: every location was marked settled *before* it was asked about, so a
/// request that threw — throttling, no network, a service error — was recorded as though the
/// geocoder had replied "nowhere". That is a permanent condition built out of a temporary one, and
/// it is unrecoverable by construction: the app never asks again.
///
/// So there are two ways to be finished with a question and they are not the same:
///
/// - **Asked, and answered with nothing.** Permanent. The same question gets the same nothing, and
///   retrying it on every refresh is how an app gets throttled.
/// - **The request failed.** Temporary, and retried. The same question can succeed in a minute.
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

    /// What is known about one location, which is what a view drawing it has to distinguish.
    enum Outcome: Equatable {
        /// Not asked yet, or asked and being waited on.
        case pending
        /// Placed.
        case placed(Resolved)
        /// Asked, and the geocoder had nothing. Permanent.
        case nothingFound
        /// The request failed. Temporary, and will be asked again.
        case failed
    }

    private var resolved: [IncidentLocation: Resolved] = [:]

    /// Locations the geocoder answered and had nothing for.
    private var unanswered: Set<IncidentLocation> = []

    /// Locations a request failed for. Deliberately **not** merged with `unanswered`.
    private(set) var failed: Set<IncidentLocation> = []

    private var isResolving = false

    /// What is already known, if anything. Never triggers a lookup — a view that asked for one
    /// while drawing would ask again on every redraw.
    func known(_ location: IncidentLocation) -> Resolved? {
        resolved[location]
    }

    func outcome(of location: IncidentLocation) -> Outcome {
        if let placed = resolved[location] {
            return .placed(placed)
        }
        if unanswered.contains(location) {
            return .nothingFound
        }
        if failed.contains(location) {
            return .failed
        }
        return .pending
    }

    /// Looks up everything not already answered, one at a time.
    ///
    /// Serial rather than concurrent: the requests are to the same service on the same terms, and
    /// issuing thirty-five at once is the behaviour limits exist for. A failure is asked again on
    /// the next call, which arrives with the next set of incidents.
    func resolve(_ locations: [IncidentLocation]) async {
        guard !isResolving else {
            return
        }
        isResolving = true
        defer { isResolving = false }

        for location in locations {
            switch outcome(of: location) {
            case .placed, .nothingFound:
                // Answered. Asking again is the behaviour that gets an app throttled.
                continue
            case .pending, .failed:
                // Never asked, or asked and it did not work. Both are worth a request.
                break
            }

            // Nothing to ask. Permanent by construction — the feed will publish the same nothing
            // next time — so this is an answer rather than a failure, and it is not retried.
            guard let query = location.query,
                  let request = MKGeocodingRequest(addressString: query) else {
                unanswered.insert(location)
                failed.remove(location)
                continue
            }

            do {
                let items = try await request.mapItems
                guard let item = items.first else {
                    // Asked, and the reply was nothing. That is the answer.
                    unanswered.insert(location)
                    failed.remove(location)
                    continue
                }
                // `location`, not `placemark`: the latter is the accessor on its way out.
                let coordinate = item.location.coordinate
                resolved[location] = Resolved(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    isArea: location.isArea
                )
                failed.remove(location)
            } catch {
                // Not an answer. Left unsettled on purpose, so the next attempt asks again.
                failed.insert(location)
            }
        }
    }
}
