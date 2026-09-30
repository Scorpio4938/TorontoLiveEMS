import SwiftUI
import TorontoLiveEMSKit

/// The colour a cell carries when it warrants attention, and whether it carries one at all.
///
/// One definition, because both arrangements apply it and the rule is policy rather than
/// taste: orange marks an exception — a dangerous category, an escalated alarm level — and
/// nothing else is coloured. See `docs/design-grammar.md`.
///
/// Returns nothing for an ordinary cell rather than a colour, because what an ordinary cell
/// looks like is the arrangement's business: a table cell is primary text, and a card's
/// supporting line is secondary. The exception is the same in both.
enum CompactAttention {

    static func colour(for cell: CompactCell) -> Color? {
        cell.warrantsAttention ? .orange : nil
    }
}

/// One cell's text, coloured by whether it warrants attention.
///
/// The only thing that renders a `CompactCell`. The compact table draws one of these per
/// column; the card arrangement draws its own text, because it uses different type — but it
/// asks `CompactAttention` the same question rather than answering it again.
///
/// Colour is applied to the text and nowhere else: no dots, no symbols, no badges. It costs
/// no width and adds nothing to the layout, which is the point — the table stays a table.
struct CompactCellText: View {

    let cell: CompactCell

    var body: some View {
        Text(cell.text ?? "")
            .font(CompactTable.font)
            .foregroundStyle(CompactAttention.colour(for: cell) ?? .primary)
    }
}
