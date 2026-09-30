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
    /// Support text is secondary here where a table cell is primary — the arrangement
    /// decides that, and the exception colour does not. Both go through `CompactAttention`
    /// so the rule that orange means an exception has one definition.
    private var twoLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                let street = cell(.primeStreet)
                Text(street.text ?? "")
                    .font(.headline)
                    .foregroundStyle(CompactAttention.colour(for: street) ?? .primary)

                Spacer(minLength: 4)

                let type = cell(.incidentType)
                Text(type.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(CompactAttention.colour(for: type) ?? .secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                let time = cell(.dispatchTime)
                Text(time.text ?? "")
                    .monospacedDigit()
                    .foregroundStyle(CompactAttention.colour(for: time) ?? .secondary)

                let alarm = cell(.alarmLevel)
                Text(alarm.text ?? "")
                    .foregroundStyle(CompactAttention.colour(for: alarm) ?? .secondary)

                let units = cell(.dispatchedUnits)
                Text(units.text ?? "")
                    .lineLimit(2)
                    .foregroundStyle(CompactAttention.colour(for: units) ?? .secondary)
            }
            .font(.footnote)
        }
    }

    private func cell(_ column: CompactColumn) -> CompactCell {
        column.cell(for: incident, timeFormat: timeFormat)
    }
}
