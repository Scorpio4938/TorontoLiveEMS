import Foundation

/// Which kind of map the app draws.
///
/// **These are modes, not MapKit's own styles**, and the mapping from one to the other lives in the
/// app — `MapStyle` is MapKit's and this package holds no MapKit at all. Satellite is deliberately
/// *not* the style MapKit names the same way: **Satellite is MapKit's `.hybrid`, not its
/// `.imagery`.** Plain imagery carries no labels at all — no street names, no place names, nothing
/// to navigate by — which was built, looked at on a phone, and rejected in those words.
///
/// **A third mode was built and removed.** Transit was the standard map with its points of interest
/// limited to public transport: `PointOfInterestCategories.including([.publicTransport])`, which is
/// a real API, checked before it was used. On screen it made no difference worth having. It is
/// recorded because the reasoning that produced it is still true and would produce it again —
/// **MapKit has no transit lines**: `MKMapView` has `showsTraffic` and no `showsTransit`, Apple's
/// own transit rendering is app-internal rather than an API, and filtering points of interest turned
/// out not to be a transit view.
public enum MapKind: String, CaseIterable, Sendable {

    /// The default: the city drawn rather than photographed.
    case standard

    /// Imagery **with labels**. Plain imagery was tried and is useless on its own.
    case satellite

    /// What to call it on screen.
    ///
    /// *Satellite* rather than *Hybrid*, because that is the word Apple's own Maps uses and the
    /// word someone looking for it will look for — and the case names MapKit would use are not the
    /// names this app offers, which is why the mapping lives elsewhere.
    public var label: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
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
    /// invisible button that reads as a layout fault rather than as a typo. `map` and `globe` have
    /// been in the set for years.
    public var systemImage: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe"
        }
    }
}
