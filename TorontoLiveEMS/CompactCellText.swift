import SwiftUI
import TorontoLiveEMSKit

/// The colour a cell carries when it warrants attention, and whether it carries one at all.
///
/// One definition, because every arrangement applies it and the rule is policy rather than
/// taste: orange marks an exception — a dangerous category, an escalated alarm level — and
/// nothing else is coloured. See `docs/design-grammar.md`.
///
/// Returns nothing for an ordinary cell rather than a colour, because what an ordinary cell
/// looks like is the arrangement's business: a table cell is primary text, a card's
/// supporting line is secondary. The exception is the same in both.
enum CompactAttention {

    static func colour(for cell: CompactCell) -> Color? {
        cell.warrantsAttention ? .orange : nil
    }
}

/// One cell's value, with a mark saying so if it came from a field the column does not name.
///
/// **The one renderer for a `CompactCell`.** The table draws one per column, the labelled
/// layout draws one per line, and the card draws one per field in its own type — which is
/// why the type and the ordinary colour are parameters here rather than fixed.
///
/// Colour is applied to the text and nowhere else: no dots, no badges, no backgrounds. It
/// costs no width and adds nothing to the layout, which is the point — the table stays a
/// table.
struct CompactCellText: View {

    let cell: CompactCell

    /// The type for the value.
    var font: Font = CompactTable.font

    /// The colour of a cell that is not an exception. The table's ordinary colour is
    /// primary; a card's supporting line is secondary.
    var ordinaryColour: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if cell.isFallback {
                // The only mark in the table, and deliberately the smallest thing that can
                // carry meaning: two arrows pointing apart, which is what an intersection is,
                // rather than a word that would cost characters the column does not have.
                //
                // Its own type rather than the value's. A card sets the address in `headline`
                // and a mark that scaled with it would stop being a footnote.
                Image(systemName: "arrow.left.and.right")
                    .font(CompactTable.font)
                    .foregroundStyle(Color.secondary)
                    .accessibilityLabel("Intersection")
            }

            Text(cell.text ?? "")
                .font(font)
                .foregroundStyle(CompactAttention.colour(for: cell) ?? ordinaryColour)
        }
    }
}
