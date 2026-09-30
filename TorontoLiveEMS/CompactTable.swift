import SwiftUI

/// The compact table's measurements, in one place.
///
/// The column header and the row cells are laid out by two different views, and they
/// have to agree on every one of these or the labels stop sitting above the values they
/// label. Stated twice, there is nothing to enforce that agreement — which is how the
/// header drifted from the rows twice before.
///
/// Kept in the app target rather than the package because these are SwiftUI values and
/// the package imports nothing from SwiftUI. `CompactColumn` is the table's *content*
/// and lives in the package, where it can be tested.
enum CompactTable {

    /// A cell's type, and the header's before weight.
    ///
    /// One size for both grids. A size difference between them would move the wrap
    /// points, and the grids have to break at the same widths to stay aligned.
    static let font: Font = .caption2

    /// The header's type: the cell type, emphasised.
    ///
    /// Weight rather than size or colour. Size would move the wrap points, and a
    /// secondary colour on 11pt text lands under the contrast needed to stay legible at
    /// that size.
    static var headerFont: Font { font.weight(.semibold) }

    /// The gap between columns, shared by the header and every row.
    ///
    /// Multi-line cells are why this is not the platform's default spacing: a cell that
    /// wraps takes width from its neighbours, so the header has to wrap exactly where
    /// the rows do, and both grids have to be told the same number.
    static let columnSpacing: CGFloat = 6

    /// The gap between one field and the next in the stacked layout.
    ///
    /// Small on purpose. A `LabeledContent` already separates a label from its value;
    /// this only has to group each pair, and at accessibility sizes a large gap would
    /// put one field per screen.
    static let stackedSpacing: CGFloat = 2

    /// Whether a text size has outgrown a compact arrangement.
    ///
    /// At that point every arrangement falls back to one labelled field per line, and the
    /// column header stands down with them. Named rather than inlined because those have to
    /// happen together: a header that stayed while its rows became something else is the
    /// same class of divergence that broke the column alignment twice.
    ///
    /// The boundary itself is the platform's. We only name it.
    static func needsLabelledRows(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }
}
