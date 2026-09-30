import SwiftUI
import TorontoLiveEMSKit

/// One incident in the compact table: six fields on a single grid row.
///
/// Every cell takes an equal share of the width, so the columns line up between rows
/// even though each row is laid out independently by the List. Empty values render as
/// empty cells — a blank Cross Street is the common case, not an error.
struct IncidentRow: View {

    let incident: Incident

    /// Kept alongside the header so the two grids stay in step.
    static let spacing: CGFloat = 6

    var body: some View {
        HStack(alignment: .top, spacing: Self.spacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                Text(column.text(for: incident) ?? "")
                    .font(.caption2)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
