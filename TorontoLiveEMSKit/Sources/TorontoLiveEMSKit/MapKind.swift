import Foundation

/// Which kind of map the app draws.
///
/// **These are modes, not MapKit's own styles**, and the mapping from one to the other lives in the
/// app — `MapStyle` is MapKit's and this package holds no MapKit at all. Two of the three are
/// deliberately *not* the style MapKit names the same way:
///
/// - **Satellite is MapKit's `.hybrid`, not its `.imagery`.** Plain imagery carries no labels at
///   all: no street names, no place names, nothing to navigate by. That was built, looked at on a
///   phone, and rejected in those words — so the satellite view is the one with labels drawn over
///   the imagery.
/// - **Transit is the standard map with its points of interest limited to public transport** —
///   streets, transit stops, and nothing else. It is the honest nearest thing rather than the real
///   thing: **MapKit has no transit lines.** `MKMapView` has `showsTraffic` and no `showsTransit`,
///   and the transit rendering in Apple's own Maps is not an API, so a view that drew subway and
///   streetcar routes is not available to be built.
public enum MapKind: String, CaseIterable, Sendable {

    /// The default: the city drawn rather than photographed.
    case standard

    /// Imagery **with labels**. Plain imagery was tried and is useless on its own.
    case satellite

    /// The standard map, with only transit stops for points of interest.
    case transit

    /// What to call it on screen.
    ///
    /// *Satellite* rather than *Hybrid*, because that is the word Apple's own Maps uses and the
    /// word someone looking for it will look for — and the case names MapKit would use are not the
    /// names this app offers, which is why the mapping lives elsewhere.
    public var label: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .transit: return "Transit"
        }
    }

    /// The glyph for this kind, and the one Apple's own Maps taught us to use.
    ///
    /// **The button wears the icon of the kind in force.** That is Apple's behaviour in its Maps:
    /// the map-type button is not a generic "change the map" symbol but the symbol of the map you
    /// are looking at, so the control states the current mode as well as offering the others.
    ///
    /// **The names are chosen for certain existence, not for best fit.** There is no symbol list on
    /// the machine this was written on, and a symbol name that is wrong draws *nothing at all* — an
    /// invisible button that reads as a layout fault rather than as a typo. `map`, `globe` and `bus`
    /// have been in the set for years. `tram` would suit Toronto better than `bus` and is newer and
    /// less certain, which is the only reason it is not here.
    public var systemImage: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe"
        case .transit: return "bus"
        }
    }
}
