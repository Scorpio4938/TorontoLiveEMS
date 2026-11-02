import Foundation

/// One place to hand to Apple Maps, with the name the app already shows for it.
///
/// **No MapKit here.** The shape of the handoff is data: a coordinate and a name. The app turns it
/// into an `MKMapItem` with that name, then calls `MKMapItem.openInMaps(launchOptions:)`, which is
/// the part that needs the platform. Keeping the name and availability here means `swift test` can
/// pin what the reader sees before Maps is asked to open.
public struct AppleMapsDestination: Equatable, Sendable {

    /// The point to open, in degrees.
    public let coordinate: Coordinate

    /// The address the detail view already shows, rather than an anonymous pin.
    ///
    /// A police call with no published intersection falls back to its call type, which is the
    /// name that screen has instead of an address.
    public let name: String

    public init(coordinate: Coordinate, name: String) {
        self.coordinate = coordinate
        self.name = name
    }
}

public extension Incident {

    /// The place to open in Apple Maps, or `nil` when there is no point to hand over.
    ///
    /// **A postal area is never a point**, an unpublished location has no place, and a geocode
    /// that has not resolved has no coordinate. All three stay silent rather than opening an
    /// anonymous spot. The name is the address the detail view already shows: the cross streets
    /// when published, otherwise the prime street.
    func appleMapsDestination(
        location: IncidentLocation,
        resolvedPoint: Coordinate?
    ) -> AppleMapsDestination? {
        guard
            !location.isArea,
            !isLocationPostalArea,
            let resolvedPoint,
            let name = crossStreets ?? primeStreet
        else {
            return nil
        }

        return AppleMapsDestination(coordinate: resolvedPoint, name: name)
    }
}

public extension PoliceCall {

    /// The place to open in Apple Maps. The Service publishes a point, so this always exists.
    ///
    /// The name is the intersection the detail view already shows. When the Service published no
    /// intersection, the call type is the name the screen has instead of one.
    var appleMapsDestination: AppleMapsDestination {
        AppleMapsDestination(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            name: crossStreets ?? callType
        )
    }
}
