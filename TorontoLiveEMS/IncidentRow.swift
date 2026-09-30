import SwiftUI
import TorontoLiveEMSKit

/// One incident, laid out to suit the reader's text size — and, on this branch, the
/// treatment being compared.
///
/// PROTOTYPE BRANCH. The treatment switch is throwaway and `master` does not have it.
/// The accessibility layout below it is production code and is unchanged.
///
/// The five-column grid that normally lives here is now `PrototypeCurrentRow`, verbatim,
/// so that it is one of the things being compared rather than the thing everything else
/// is measured against in a different file.
struct IncidentRow: View {

    let incident: Incident

    /// The reader's chosen clock, from Settings.
    let timeFormat: DispatchTimeFormat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @AppStorage(PrototypeDefaults.tableStyle)
    private var prototypeStyle: PrototypeTableStyle = .current

    var body: some View {
        if prototypeStyle == .cards {
            treatment
                // A card separates itself from the next one; the system's hairline on top
                // of that was doing the same job twice, and worse.
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
        } else {
            treatment
        }
    }

    @ViewBuilder
    private var treatment: some View {
        if CompactTable.outgrowsTheGrid(dynamicTypeSize) {
            // Accessibility sizes win over the treatment. Five columns of anything cannot
            // be read at those sizes, so the comparison is meaningless there.
            stacked
        } else {
            switch prototypeStyle {
            case .current:
                PrototypeCurrentRow(incident: incident, timeFormat: timeFormat)
            case .hierarchy:
                PrototypeHierarchyRow(incident: incident, timeFormat: timeFormat)
            case .instrument:
                PrototypeInstrumentRow(incident: incident, timeFormat: timeFormat)
            case .cards:
                PrototypeCardsRow(incident: incident, timeFormat: timeFormat)
            }
        }
    }

    /// One field per line, each labelled. Production code, unchanged by the prototype.
    ///
    /// The label stays the table's own type rather than the platform's body size: what
    /// fails at these sizes is the five-column width, not the size of the text, and
    /// `caption2` at an accessibility size is already large.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: CompactTable.stackedSpacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                LabeledContent {
                    CompactCellText(cell: column.cell(for: incident, timeFormat: timeFormat))
                } label: {
                    Text(column.label)
                        .font(CompactTable.font)
                }
            }
        }
    }
}
