import SwiftUI
import TorontoLiveEMSKit

/// One cell's text, coloured by whether it warrants attention.
///
/// The only place the attention colour is applied. Both layouts show the same cells —
/// one across a row, one down a column — so the rule that an escalated alarm level or a
/// dangerous category is orange lives here once rather than in each of them.
///
/// Colour is applied to the text and nowhere else: no dots, no symbols, no badges. It
/// costs no width and adds nothing to the layout, which is the point — the table stays a
/// table. See `docs/design-grammar.md`.
struct CompactCellText: View {

    let cell: CompactCell

    var body: some View {
        Text(cell.text ?? "")
            .font(CompactTable.font)
            .foregroundStyle(cell.warrantsAttention ? Color.orange : Color.primary)
    }
}
