import SwiftUI
import TorontoLiveEMSKit

/// Every field of one row, one per line, each named.
///
/// This is the layout both arrangements fall back to when the reader's text size outgrows a compact
/// one: a grid cannot hold its columns at those sizes, and an unlabelled row of numbers is no
/// better than a table that does not fit — `19:54  3  3 Pump` names nothing.
///
/// `LabeledContent` stacks a label above its value at these sizes by itself, so there is no size
/// handling in here. Three views read this: the table, the card, and the previews. One definition
/// because they have to agree about it, and because the failure it prevents — a screen of figures
/// with nothing to say what they are — is what issue #9 was about.
struct CompactLabeledRows<Row>: View {

    let row: Row

    /// The columns to name, in order. However many the source declares.
    let columns: [CompactColumn<Row>]

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    var body: some View {
        VStack(alignment: .leading, spacing: CompactTable.stackedSpacing) {
            ForEach(columns) { column in
                LabeledContent {
                    CompactCellText(cell: column.cell(row, timeFormat))
                } label: {
                    Text(column.label)
                        .font(CompactTable.font)
                }
            }
        }
    }
}
