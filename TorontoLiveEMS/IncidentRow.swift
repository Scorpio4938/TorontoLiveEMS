import SwiftUI
import TorontoLiveEMSKit

/// One incident in the compact table: five fields on a single grid row.
///
/// Every cell takes an equal share of the width, so columns line up between rows even
/// though the List lays each row out independently.
///
/// A cell is never truncated and never moved out of its column. When a value needs more
/// room than the column has, it wraps onto another line *within that cell*, so a long
/// apparatus roster makes its own column taller and leaves the other four alone.
///
/// Colour is applied to the text itself and nowhere else — no dots, no symbols, no
/// badges. It costs no width and adds nothing to the layout, which is the point: the
/// table stays a table.
struct IncidentRow: View {

    let incident: Incident

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    /// Kept alongside the header so the two grids stay in step.
    static let spacing: CGFloat = 6

    var body: some View {
        HStack(alignment: .top, spacing: Self.spacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                let cell = column.cell(for: incident, timeFormat: timeFormat)
                Text(cell.text ?? "")
                    .font(.caption2)
                    .foregroundStyle(cell.warrantsAttention ? Color.orange : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
