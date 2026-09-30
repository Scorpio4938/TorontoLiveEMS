import SwiftUI

/// PROTOTYPE — throwaway.
enum PrototypeDefaults {

    /// Where the chosen treatment is kept between launches. One definition, because the
    /// screen, every row and the switcher all read it, and a typo in one of them would
    /// look like a difference between treatments rather than a typo.
    static let tableStyle = "prototypeTableStyle"
}

/// PROTOTYPE — throwaway. Not production code, and not a decision.
///
/// Four ways of drawing the same five fields for the same incident, so they can be
/// compared side by side in the Simulator against the live feed rather than argued about
/// in prose. The data, the columns and the wording are identical in all four; only the
/// presentation differs.
///
/// This lives on the `prototype/table-treatments` branch and must not reach `master`.
/// The answer it produces — which treatment was chosen, and why — goes in issue #12, and
/// the chosen treatment gets built properly afterwards. Delete this whole folder.
///
/// Switch treatments with the floating control at the bottom of the screen.
enum PrototypeTableStyle: String, CaseIterable, Identifiable {

    /// What ships today: five equal columns, one type size, one weight, colour only on
    /// exceptions. The control in the comparison.
    case current

    /// The same grid, but the two fields that identify an incident carry more weight than
    /// the three that describe it, and each row is given more air.
    case hierarchy

    /// The same grid read as an instrument panel: monospaced throughout, monospaced
    /// digits on the numbers, a quiet body and a loud header rule.
    case instrument

    /// Not a grid at all. Two lines per incident: where and what on the first, when and
    /// who on the second, on a card.
    ///
    /// This deliberately breaks the five-column decision, which is the point of showing
    /// it — an argument in the design grammar warned against exactly this kind of layout,
    /// and it is worth seeing whether that warning is right on this data.
    case cards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .current: return "Current"
        case .hierarchy: return "Hierarchy"
        case .instrument: return "Instrument"
        case .cards: return "Cards"
        }
    }

    /// Whether the grid's column header is shown at all. Cards carry their own labels'
    /// worth of structure, so a column header above them would name five columns that are
    /// no longer there.
    var showsColumnHeader: Bool { self != .cards }
}
