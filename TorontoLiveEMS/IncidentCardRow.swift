import SwiftUI
import TorontoLiveEMSKit

/// One incident as a block: where and what on the first line, when and who on the second.
///
/// **Draws no block of its own.** The screen puts one of these inside a `Section` of a
/// grouped `List`, and the platform forms the block — its background, its corner radius,
/// its insets, its gaps. That is the reason this arrangement exists, and it is rule 17 of
/// `docs/design-grammar.md`: do not hand-roll what the system provides.
///
/// A hand-rolled version of this was built and looked at, and rejected for exactly that
/// reason. It drew `.regularMaterial` inside a `RoundedRectangle(cornerRadius: 10)` with
/// padding picked by hand. That version is on the `prototype/table-treatments` branch and
/// is not what ships.
///
/// At accessibility text sizes it becomes `IncidentLabeledRows`, the same fallback the
/// compact table uses. Two unlabelled lines are not an accessibility layout: `19:54  2
/// P231, P234` names nothing, and a reader who needs large text is the last person to be
/// handed a row of bare figures.
struct IncidentCardRow: View {

    let incident: Incident

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if CompactTable.needsLabelledRows(dynamicTypeSize) {
            IncidentLabeledRows(incident: incident, timeFormat: timeFormat)
        } else {
            twoLines
        }
    }

    /// The ordinary arrangement: where and what above, when and who below.
    ///
    /// Every value goes through `CompactCellText`, which is also what the table draws. The
    /// type and the ordinary colour are the only things this arrangement chooses; the
    /// exception colour, and the mark on a substituted address, are decided once for both.
    private var twoLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                CompactCellText(cell: cell(.primeStreet), font: .headline)

                Spacer(minLength: 4)

                CompactCellText(
                    cell: cell(.incidentType),
                    font: .subheadline,
                    ordinaryColour: .secondary
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                CompactCellText(
                    cell: cell(.dispatchTime),
                    font: .footnote,
                    ordinaryColour: .secondary
                )
                .monospacedDigit()

                CompactCellText(
                    cell: cell(.alarmLevel),
                    font: .footnote,
                    ordinaryColour: .secondary
                )

                CompactCellText(
                    cell: cell(.dispatchedUnits),
                    font: .footnote,
                    ordinaryColour: .secondary
                )
                .lineLimit(2)
            }
        }
    }

    private func cell(_ column: CompactColumn) -> CompactCell {
        column.cell(for: incident, timeFormat: timeFormat)
    }
}
