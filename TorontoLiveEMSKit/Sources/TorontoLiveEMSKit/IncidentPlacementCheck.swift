import Foundation

/// Whether an incident's resolved point and the station its Area names disagree enough to warn.
///
/// **Pure arithmetic, in the package.** The app has already geocoded the point and read the
/// station from the City's file; this type decides whether those two published facts are far
/// enough apart to be impossible. Nothing here imports MapKit or reaches the network.
public enum IncidentPlacementCheck {

    /// The distance beyond which an incident's placement is treated as wrong.
    ///
    /// **10 km, derived from the City's own run areas.** Measured against those areas, the
    /// distance from each station to the farthest point of its own area has a median of 2.6 km
    /// and a **maximum of 6.84 km, at station 211**. A correct incident whose point comes from
    /// the published intersection cannot be legitimately further than that from the station the
    /// City files it under, and 10 km clears the worst real area by about 45%. It is far below
    /// what a genuinely wrong placement produces — another part of the city is 15–30 km, another
    /// city is hundreds — so it fires on the impossible and not on the merely imprecise.
    /// Tightening it to 5 km would reintroduce false alarms across the largest areas, which is
    /// why the measurement is written down rather than the number alone.
    public static let thresholdMetres: Double = 10_000

    /// Whether the incident's point and its Area's station are far enough apart to warn.
    ///
    /// **Silence is the default.** A postal area is an extent, never a point. A street-name
    /// geocode is a point the map draws as a pin, so it is checked too: the City publishes no
    /// street number, so that pin is the only point fact there is, and the note says the placement
    /// may be off rather than that the incident is impossible. A `nil` point means the geocoder
    /// has not answered; a `nil` station means the Area is missing or is not one of the 84. None
    /// of those is a disagreement, so none of them warns.
    ///
    /// The threshold is a strict "beyond": a point exactly 10 km away is still plausible.
    public static func shouldWarn(
        location: IncidentLocation,
        resolvedPoint: Coordinate?,
        station: FireStation?
    ) -> Bool {
        guard
            !location.isArea,
            let resolvedPoint,
            let station
        else {
            return false
        }

        let stationPoint = Coordinate(
            latitude: station.coordinate.latitude,
            longitude: station.coordinate.longitude
        )
        return distanceMetres(from: resolvedPoint, to: stationPoint) > thresholdMetres
    }

    /// Great-circle distance on a mean-radius sphere, in metres.
    ///
    /// Haversine, rather than a projection: the answer is a distance between two points, not a
    /// position. The mean radius is 6,371,008.8 m (IUGG), and the difference from a local radius
    /// is far below the threshold's tolerance.
    ///
    /// CoreLocation's `distance(from:)` would do this too, and would put CoreLocation in the
    /// package. The issue asks for pure arithmetic here, with no MapKit and no network, so the
    /// formula stays in the package and the view keeps its MapKit.
    private static func distanceMetres(from start: Coordinate, to end: Coordinate) -> Double {
        let latitude1 = start.latitude * .pi / 180
        let latitude2 = end.latitude * .pi / 180
        let latitudeDelta = (end.latitude - start.latitude) * .pi / 180
        let longitudeDelta = (end.longitude - start.longitude) * .pi / 180

        let haversine =
            sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(latitude1) * cos(latitude2)
                * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return 2 * earthRadiusMetres * asin(min(1, sqrt(haversine)))
    }

    private static let earthRadiusMetres = 6_371_008.8
}
