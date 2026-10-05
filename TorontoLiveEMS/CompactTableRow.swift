import SwiftUI
import TorontoLiveEMSKit

/// One row of the compact table, laid out to suit the reader's text size.
///
/// At ordinary text sizes this is the grid: every column on a single row, each an equal share of
/// the width, so columns line up between rows even though the List lays each row out independently.
///
/// At accessibility text sizes it becomes one field per line, each with its own label. A compact
/// grid cannot work there — the text scales up roughly threefold, so five columns would need
/// something like 450pt of width and have about 340 — and because a cell wraps rather than
/// truncates, the grid does not clip when it runs out of room. It grows. A row becomes a screenful
/// with one word per line.
///
/// Both of those figures are estimates rather than measurements, made on a machine with no way to
/// see the result. See `docs/design-decisions.md`.
///
/// The line is the system's, not ours: `DynamicTypeSize.isAccessibilitySize` is the boundary the
/// platform already draws, and `LabeledContent` already knows how to lay a label and its value out
/// on either side of it. Neither is reimplemented here.
///
/// **Generic over the row, and told its columns.** This is one of the views the fire page and the
/// police page share: what differs between them is the set of columns and the model behind it, and
/// nothing here assumes either. The column count is the array's.
struct CompactTableRow<Row>: View {

    let row: Row

    /// The columns to draw, in order. However many the source declares.
    let columns: [CompactColumn<Row>]

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if CompactTable.needsLabelledRows(dynamicTypeSize) {
            CompactLabeledRows(row: row, columns: columns, timeFormat: timeFormat)
        } else {
            grid
        }
    }

    /// Every column on one row, each an equal share of the width.
    ///
    /// A cell is never truncated and never moved out of its column. When a value needs more room
    /// than the column has it wraps onto another line *within that cell*, so a long roster makes its
    /// own column taller and leaves its neighbours alone.
    private var grid: some View {
        HStack(alignment: .top, spacing: CompactTable.columnSpacing) {
            ForEach(columns) { column in
                CompactCellText(cell: column.cell(row, timeFormat))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
