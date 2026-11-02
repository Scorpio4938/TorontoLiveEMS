import Foundation

/// A point in degrees, shared by the package's map-facing calculations.
///
/// **No MapKit here.** This is the shape the app passes between a geocoded point and the rules
/// that need to measure it or hand it to Maps; the app converts it to `CLLocation` at the edge.
///
/// The other coordinate types in the package stay nested in their decoded models — `FireStation`,
/// `PoliceFacility`, `PostalAreas`, `PoliceDivision` — because those are part of each file's wire
/// shape. This is the plain pair for calculations that do not decode anything.
public struct Coordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
