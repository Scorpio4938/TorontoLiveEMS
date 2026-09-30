import SwiftUI
import TorontoLiveEMSKit

/// One incident in the compact table: six fields on a single grid row, plus a
/// full-width line beneath it when a value will not fit its column.
///
/// Every cell takes an equal share of the width, so columns line up between rows even
/// though the List lays each row out independently. Empty values render as empty cells
/// — a blank Cross Street is the common case, not an error.
struct IncidentRow: View {

    let incident: Incident

    /// Kept alongside the header so the two grids stay in step.
    static let spacing: CGFloat = 6

    /// A value longer than this gets a line of its own beneath the row.
    ///
    /// A column is roughly a sixth of a phone's width, which at this text size is about
    /// nine or ten characters per line across the two lines a cell is allowed. Past
    /// that a value would have to be squeezed or truncated, and the rule is that no
    /// apparatus name is truncated. On a Mac the column is wide enough that the
    /// continuation line will seldom be needed; the threshold is set for the narrow
    /// case, which is the one that breaks.
    static let maximumColumnCharacters = 18

    private var units: [DispatchedUnit] {
        DispatchedUnit.roster(from: incident.dispatchedUnits)
    }

    private var rosterText: String {
        units.map(\.display).joined(separator: ", ")
    }

    private var rosterNeedsOwnLine: Bool {
        rosterText.count > Self.maximumColumnCharacters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: Self.spacing) {
                ForEach(CompactColumn.allCases, id: \.self) { column in
                    Text(cellText(for: column))
                        .font(.caption2)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if rosterNeedsOwnLine {
                Text(rosterText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// The cell's text, with one exception to the column's default.
    ///
    /// When the roster moves to its own line the column keeps a count, so that a row is
    /// never blank in a column that has data — and because response size is itself the
    /// signal. The roster below is complete; nothing is dropped.
    private func cellText(for column: CompactColumn) -> String {
        guard column == .dispatchedUnits else {
            return column.text(for: incident) ?? ""
        }
        guard !units.isEmpty else {
            return ""
        }
        guard rosterNeedsOwnLine else {
            return rosterText
        }
        return "\(units.count) units"
    }
}
