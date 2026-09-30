import SwiftUI
import TorontoLiveEMSKit

/// One incident, laid out to suit the reader's text size.
///
/// At ordinary text sizes this is the compact table: five fields on a single grid row,
/// each an equal share of the width, so columns line up between rows even though the
/// List lays each row out independently.
///
/// At accessibility text sizes it becomes one field per line, each with its own label.
/// Five columns cannot work there — the text scales up roughly threefold, so the row
/// needs something like 450pt of width to hold five usable columns and has about 340 —
/// and because a cell wraps rather than truncates, the grid does not clip when it runs
/// out of room. It grows. An incident becomes a screenful with one word per line.
///
/// Both of those figures are estimates rather than measurements, made on a machine with
/// no way to see the result. See `docs/design-decisions.md`.
///
/// The line is the system's, not ours: `DynamicTypeSize.isAccessibilitySize` is the
/// boundary the platform already draws, and `LabeledContent` already knows how to lay a
/// label and its value out on either side of it. Neither is reimplemented here.
///
/// Everything about this view's size and spacing comes from `CompactTable`, which the
/// column header in `ContentView` reads too. The two are separate views that have to
/// agree, so nothing about either is stated in either one.
struct IncidentRow: View {

    let incident: Incident

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if CompactTable.outgrowsTheGrid(dynamicTypeSize) {
            stacked
        } else {
            grid
        }
    }

    /// Five fields on one row, each an equal share of the width.
    ///
    /// A cell is never truncated and never moved out of its column. When a value needs
    /// more room than the column has it wraps onto another line *within that cell*, so a
    /// long apparatus roster makes its own column taller and leaves the other four alone.
    private var grid: some View {
        HStack(alignment: .top, spacing: CompactTable.columnSpacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                CompactCellText(cell: column.cell(for: incident, timeFormat: timeFormat))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// One field per line, each labelled.
    ///
    /// The label stays the table's own type rather than the platform's body size: what
    /// fails at these sizes is the five-column width, not the size of the text, and
    /// `caption2` at an accessibility size is already large. Keeping it also keeps one
    /// incident looking like the same product in both layouts.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: CompactTable.stackedSpacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                LabeledContent {
                    CompactCellText(cell: column.cell(for: incident, timeFormat: timeFormat))
                } label: {
                    Text(column.label)
                        .font(CompactTable.font)
                }
            }
        }
    }
}
