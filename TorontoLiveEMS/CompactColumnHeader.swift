import SwiftUI
import TorontoLiveEMSKit

/// The column labels, held still above the rows they label.
///
/// A view of its own rather than a private property of the screen, because the previews
/// have to render the real one. A preview that drew its own copy of the header could
/// disagree with the app, and a header that disagrees with its rows is the failure that
/// broke the column alignment twice.
///
/// No horizontal padding of its own: the List supplies it, which is the point. The
/// chevron placeholder below is the other half of that — see the comment on it.
struct CompactColumnHeader: View {

    var body: some View {
        HStack(alignment: .top, spacing: CompactTable.columnSpacing) {
            ForEach(CompactColumn.allCases, id: \.self) { column in
                Text(column.headerLabel)
                    .font(CompactTable.headerFont)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Every row is a NavigationLink, and its disclosure chevron takes a slice of
            // the row's trailing edge — so the rows lay their five columns out in less
            // width than the header would otherwise claim. Reserving the same slice keeps
            // the labels above the values instead of a little to the right of them.
            // Left at the default font so its width matches the system's chevron.
            Image(systemName: "chevron.right")
                .opacity(0)
        }
    }
}
