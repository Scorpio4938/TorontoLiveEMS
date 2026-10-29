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
    /// **`standard` is outlined and `satellite` is filled**, which is not how this started: both were
    /// filled so that the two would read as siblings in the capsule. The plain `map` was preferred for
    /// the standard kind when the control was looked at on a device, and the reason for the pairing did
    /// not survive that preference — two glyphs are siblings because they sit in one capsule, not
    /// because they share an outline weight.
    ///
    /// **The names are checked rather than remembered**, and they were not always: this comment used to
    /// say they could not be, which was true until the app grew a test that asks the system's own
    /// catalogue. A symbol name that does not exist draws *nothing at all* — no warning, no
    /// placeholder, just a gap in the capsule — so all three sets of control glyphs are asserted there
    /// now: the map kinds, the filter, and the nine incident kinds.
    public var systemImage: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas.fill"
        }
    }
}
