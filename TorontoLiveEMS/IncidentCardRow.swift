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
/// Nothing here is a grid, so nothing here needs the accessibility layout the compact
/// table uses. Two stacked lines are already what that layout turns the table into.
struct IncidentCardRow: View {

    let incident: Incident

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    private func cell(_ column: CompactColumn) -> CompactCell {
        column.cell(for: incident, timeFormat: timeFormat)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(cell(.primeStreet).text ?? "")
                    .font(.headline)

                Spacer(minLength: 4)

                Text(cell(.incidentType).text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(cell(.incidentType).warrantsAttention
                                     ? Color.orange : Color.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(cell(.dispatchTime).text ?? "")
                    .monospacedDigit()
                Text(cell(.alarmLevel).text ?? "")
                    .foregroundStyle(cell(.alarmLevel).warrantsAttention
                                     ? Color.orange : Color.secondary)
                Text(cell(.dispatchedUnits).text ?? "")
                    .lineLimit(2)
            }
            .font(.footnote)
            .foregroundStyle(Color.secondary)
        }
    }
}
