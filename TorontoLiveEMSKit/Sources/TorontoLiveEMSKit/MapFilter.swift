import Foundation

/// Which feeds the map draws.
///
/// **A question about where a mark came from**, which is the reason `IncidentMark` carries a `Source`
/// at all — this is that one field, asked three ways. It is a stored preference rather than page state
/// for the same reason the map kind is: the control lives in the app's chrome and the map lives inside
/// a page, and neither of them knows the other exists.
///
/// **Only ever the two sources, never a kind.** A filter over thirty police call types and sixty-nine
/// City incident types would be a control nobody would use; fire or police is a question a reader
/// actually has. Narrowing further is a different feature, and this is deliberately not it.
///
/// **The one exception is time, and only for police.** Four hours of calls is about a hundred marks,
/// which is more than a map can say anything with, so the police option draws the recent window and a
/// fourth option draws all of it. It is a *fourth row in the same picker* rather than a second control,
/// because a fifth button in a capsule of four is worse than a fourth line in a menu of three — and it
/// is only police, because the City's fire feed has no window: an incident from three hours ago is
/// still on it because it is still happening.
public enum MapFilter: String, CaseIterable, Sendable {

    case all
    case fire
    case police
    /// Police calls from the whole four hours the Service holds, rather than the recent window.
    case policeAll

    /// The name a reader sees in the menu.
    public var label: String {
        switch self {
        case .all: return "Both Feeds"
        case .fire: return "Fire Only"
        case .police: return "Police Only"
        case .policeAll: return "Police · Four Hours"
        }
    }

    /// The glyph beside it.
    ///
    /// `all` wears the filter's own glyph, **outlined**, because unfiltered is the state the control is
    /// named for. The two sources wear the glyphs they already wear as a *kind* on the map — a flame and
    /// a shield, **both filled** — so choosing either turns the control from an outline into a solid,
    /// and the glyph says which feed is on screen rather than merely that something is filtered.
    public var systemImage: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .fire: return "flame.fill"
        case .police, .policeAll: return "shield.fill"
        }
    }

    /// Whether a mark survives the filter.
    public func keeps(_ mark: IncidentMark) -> Bool {
        switch self {
        case .all: return true
        case .fire: return mark.source == .fire
        case .police, .policeAll: return mark.source == .police
        }
    }
}
