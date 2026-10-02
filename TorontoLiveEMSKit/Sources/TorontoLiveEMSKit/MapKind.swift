import Foundation

/// Which kind of map the app draws.
///
/// In the package with the other stored preferences, and a string-backed enum for the same reason
/// they are: `@AppStorage` stores a `String`, and `MapStyle` — the thing the map actually takes —
/// is a struct carrying parameters, which cannot be stored at all. The app turns one into the
/// other in exactly one place.
///
/// **Three kinds, because three is what the platform has.** MapKit's styles are `.standard`,
/// `.imagery` and `.hybrid`; there is no transit style, because transit is a *content* mode in
/// Apple's own Maps rather than a rendering style MapKit exposes. Offering a fourth thing called
/// Transit would be offering something the platform does not do, so the nearest honest lever —
/// traffic — would be a toggle beside these, not a kind among them.
public enum MapKind: String, CaseIterable, Sendable {

    /// The default: the city drawn rather than photographed.
    case standard

    /// Satellite imagery, without labels.
    case imagery

    /// Satellite imagery with labels drawn over it.
    case hybrid

    /// What to call it on screen.
    ///
    /// The case is MapKit's word and the label is the reader's: `imagery` is what the API calls it
    /// and *Satellite* is what Apple's own Maps calls it, which is the word someone looking for it
    /// will look for.
    public var label: String {
        switch self {
        case .standard: return "Standard"
        case .imagery: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }

    /// The glyph for this kind, and the one Apple's own Maps taught us to use.
    ///
    /// **The button wears the icon of the kind in force.** That is Apple's behaviour in its Maps:
    /// the map-type button is not a generic "change the map" symbol but the symbol of the map you
    /// are looking at, so the control states the current mode as well as offering the others. The
    /// control asks each kind for its glyph and draws the current one.
    ///
    /// **The names are chosen for certain existence, not for best fit.** There is no symbol list
    /// on the machine this was written on, and a symbol name that is wrong draws *nothing at all* —
    /// an invisible button that reads as a layout fault rather than as a typo. `map`, `globe` and
    /// `map.fill` have been in the set since its first release. `map.fill` for hybrid is the
    /// weakest of the three: Apple's own Maps has no hybrid mode, so there was nothing to copy.
    public var systemImage: String {
        switch self {
        case .standard: return "map"
        case .imagery: return "globe"
        case .hybrid: return "map.fill"
        }
    }
}
