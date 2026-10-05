import SwiftUI
import TorontoLiveEMSKit

/// One row as a block: the first two columns on its first line, the rest on its second.
///
/// **Draws no block of its own.** The screen puts one of these inside a `Section` of a grouped
/// `List`, and the platform forms the block — its background, its corner radius, its insets, its
/// gaps. That is the reason this arrangement exists, and it is rule 17 of `docs/design-grammar.md`:
/// do not hand-roll what the system provides.
///
/// A hand-rolled version of this was built and looked at, and rejected for exactly that reason. It
/// drew `.regularMaterial` inside a `RoundedRectangle(cornerRadius: 10)` with padding picked by
/// hand. That version is on the `prototype/table-treatments` branch and is not what ships.
///
/// At accessibility text sizes it becomes `CompactLabeledRows`, the same fallback the table uses.
/// Two unlabelled lines are not an accessibility layout: `19:54  2  P231, P234` names nothing, and
/// a reader who needs large text is the last person to be handed a row of bare figures.
///
/// **The split is two and the rest, which is the shape both sources share.** What each line *means*
/// is the source's business, and it says so by the order it declares its columns in: fire reads
/// where and what, then when and who; police will read an intersection and a call type, then a time
/// and a division. The layout is one, so the two cards cannot come to look like different apps.
struct CompactCardRow<Row>: View {

    let row: Row

    /// The columns in the order the card reads them: the first two are its first line, and
    /// everything after them is its second.
    let columns: [CompactColumn<Row>]

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if CompactTable.needsLabelledRows(dynamicTypeSize) {
            CompactLabeledRows(row: row, columns: columns, timeFormat: timeFormat)
        } else {
            twoLines
        }
    }

    /// The ordinary arrangement: two columns above, the rest below.
    ///
    /// Every value goes through `CompactCellText`, which is also what the table draws, and every
    /// cell after the first two is monospaced-digit and capped at two lines. Both were once applied
    /// to particular columns by name — the clock and the roster — and are now applied to the
    /// second line as a whole, which is the same thing for fire and the right thing for a source
    /// whose second line holds something else. A digit-spacing modifier does nothing to text
    /// without digits, so the fire card is unchanged by it.
    private var twoLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let first = cell(at: 0) {
                    CompactCellText(cell: first, font: .headline)
                }

                Spacer(minLength: 4)

                if let second = cell(at: 1) {
                    CompactCellText(
                        cell: second,
                        font: .subheadline,
                        ordinaryColour: .secondary
                    )
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                ForEach(columns.dropFirst(2)) { column in
                    CompactCellText(
                        cell: column.cell(row, timeFormat),
                        font: .footnote,
                        ordinaryColour: .secondary
                    )
                    .monospacedDigit()
                    .lineLimit(2)
                }
            }
        }
    }

    /// The cell for one slot, or nothing where the source declares fewer columns than the layout
    /// has places for.
    ///
    /// Indexed rather than named, because the slots are positions. A source with three columns gets
    /// three cells and one empty place rather than a crash, which is what indexing into the array
    /// without this would be.
    private func cell(at index: Int) -> CompactCell? {
        guard columns.indices.contains(index) else { return nil }
        return columns[index].cell(row, timeFormat)
    }
}
