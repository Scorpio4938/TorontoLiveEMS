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
/// **The time is deliberately not in here.** Four hours of calls is about a hundred marks, so the
/// police marks are drawn from the recent window — but *how far back* is a switch in the menu below
/// this picker, not a fourth row in it. A picker where three rows answer "which feed" and one answers
/// "how far back" is a picker nobody can read, which is what the fourth row turned out to be.
public enum MapFilter: String, CaseIterable, Sendable {

    case all
    case fire
    case police

    /// The name a reader sees in the menu.
    public var label: String {
        switch self {
        case .all: return "Both Feeds"
        case .fire: return "Fire Only"
        case .police: return "Police Only"
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
        case .police: return "shield.fill"
        }
    }

    public func keeps(_ mark: IncidentMark) -> Bool {
        switch self {
        case .all: return true
        case .fire: return mark.source == .fire
        case .police: return mark.source == .police
        }
    }
}
