import SwiftUI
import TorontoLiveEMSKit

/// One incident in the compact table: five fields on a single grid row.
///
/// Every cell takes an equal share of the width, so columns line up between rows even
/// though the List lays each row out independently.
///
/// A cell is never truncated and never moved out of its column. When a value needs more
/// room than the column has, it wraps onto another line *within that cell*, so a long
/// apparatus roster makes its own column taller and leaves the other four alone. That is
/// the whole of the width strategy: five columns, each of which grows downward rather
/// than sideways.
struct IncidentRow: View {

    let incident: Incident

    /// Kept alongside the header so the two grids stay in step.
    static let spacing: CGFloat = 6

    var body: some View {
        HStack(alignment: .top, spacing: Self.spacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                Text(column.text(for: incident) ?? "")
                    .font(.caption2)
                    // Let the cell take as many lines as it needs: no truncation, and
                    // no moving the value somewhere else.
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
