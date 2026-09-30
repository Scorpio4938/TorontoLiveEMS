import SwiftUI
import TorontoLiveEMSKit

/// One incident in the compact table: six fields on a single grid row, plus a
/// full-width line beneath it for any value that will not fit its column.
///
/// Every cell takes an equal share of the width, so columns line up between rows even
/// though the List lays each row out independently.
///
/// The long-value rule is deliberately not specific to Dispatched Units. A working fire
/// is the obvious case, but `3950 LAWRENCE AVE E / 3967 LAWRENCE AVE E` is forty
/// characters in a Cross Street column that fits ten per line, and the rule is that
/// nothing is truncated. Any column can overflow.
struct IncidentRow: View {

    let incident: Incident

    /// Kept alongside the header so the two grids stay in step.
    static let spacing: CGFloat = 6

    /// A value longer than this gets a line of its own beneath the row.
    ///
    /// A column is roughly a sixth of a phone's width, which at this text size is about
    /// nine or ten characters per line across the two lines a cell is allowed. Past
    /// that the value would have to be squeezed or truncated, and the rule is that
    /// nothing is truncated. On a Mac the columns are wide enough that the threshold is
    /// conservative; it is set for the narrow case, which is the one that breaks.
    static let maximumColumnCharacters = 18

    var body: some View {
        let values = Self.values(for: incident)
        let overflowing = CompactColumn.allCases.filter { column in
            (values[column] ?? "").count > Self.maximumColumnCharacters
        }

        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: Self.spacing) {
                ForEach(CompactColumn.allCases, id: \.self) { column in
                    Text(overflowing.contains(column) ? "" : (values[column] ?? ""))
                        .font(.caption2)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ForEach(overflowing, id: \.self) { column in
                HStack(alignment: .top, spacing: 4) {
                    Text("\(column.label):")
                        .font(.caption2.weight(.semibold))
                    Text(values[column] ?? "")
                        .font(.caption2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Every column's text for this incident, resolved once per render.
    ///
    /// `CompactColumn` remains the single source of truth for what a column shows; this
    /// only decides where it goes.
    private static func values(for incident: Incident) -> [CompactColumn: String] {
        var values: [CompactColumn: String] = [:]
        for column in CompactColumn.allCases {
            values[column] = column.text(for: incident) ?? ""
        }
        return values
    }
}
