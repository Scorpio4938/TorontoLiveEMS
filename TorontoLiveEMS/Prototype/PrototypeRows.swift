import SwiftUI
import TorontoLiveEMSKit

// PROTOTYPE — throwaway. Four drawings of the same row, over the same data.
//
// No tests, no abstraction, no error handling: the only thing these have to do is be
// lookable-at side by side. Delete the whole Prototype folder when the question is
// answered.

/// What ships today. The control for the comparison.
struct PrototypeCurrentRow: View {

    let incident: Incident
    let timeFormat: DispatchTimeFormat

    var body: some View {
        HStack(alignment: .top, spacing: CompactTable.columnSpacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                CompactCellText(cell: column.cell(for: incident, timeFormat: timeFormat))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// The identity of an incident carries more weight than its description.
///
/// Where and what are what the eye needs; when, how serious and who is attending are
/// what it reads next. Same five columns, same size, same colour — only weight separates
/// them, because at 11pt there is no room for a second grey tier.
struct PrototypeHierarchyRow: View {

    let incident: Incident
    let timeFormat: DispatchTimeFormat

    private static let identifying: Set<CompactColumn> = [.primeStreet, .incidentType]

    var body: some View {
        HStack(alignment: .top, spacing: CompactTable.columnSpacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                let cell = column.cell(for: incident, timeFormat: timeFormat)
                Text(cell.text ?? "")
                    .font(Self.identifying.contains(column)
                          ? .caption2.weight(.semibold)
                          : .caption2)
                    .foregroundStyle(cell.warrantsAttention ? Color.orange : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // More air than the platform's default, which is what separates two incidents
        // when the weight alone is not enough to do it.
        .padding(.vertical, 3)
    }
}

/// An instrument panel: monospaced throughout, digits that do not jitter, a quiet body
/// under a loud header.
struct PrototypeInstrumentRow: View {

    let incident: Incident
    let timeFormat: DispatchTimeFormat

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                let cell = column.cell(for: incident, timeFormat: timeFormat)
                Text(cell.text ?? "")
                    .font(.caption2.monospaced())
                    .monospacedDigit()
                    .foregroundStyle(colour(for: column, cell: cell))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func colour(for column: CompactColumn, cell: CompactCell) -> Color {
        if cell.warrantsAttention {
            return .orange
        }
        // The location is where the eye lands; the rest supports it.
        return column == .primeStreet ? .primary : .secondary
    }
}

/// Not a grid at all: where and what on the first line, when and who on the second.
///
/// This breaks the five-column decision on purpose. The design grammar argued against
/// card layouts — "don't put the table inside a giant decorative card" — and it is worth
/// seeing whether that objection holds up on this data or whether a card is simply
/// easier to read on a phone.
struct PrototypeCardsRow: View {

    let incident: Incident
    let timeFormat: DispatchTimeFormat

    private func cell(_ column: CompactColumn) -> CompactCell {
        column.cell(for: incident, timeFormat: timeFormat)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(cell(.primeStreet).text ?? "")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                Text(cell(.incidentType).text ?? "")
                    .font(.caption.weight(.medium))
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
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
