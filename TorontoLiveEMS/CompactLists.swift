import SwiftUI
import TorontoLiveEMSKit

// The rows of one source, arranged the way the reader chose.
//
// Both arrangements are views of their own rather than private methods of the screen, because the
// previews have to render the real ones. A preview that draws its own copy can disagree with the
// app, and two views disagreeing about a column layout is exactly what broke the header alignment
// twice.
//
// **Both are generic, and both are told their columns.** This is where the fire page and the police
// page meet: the same grid, the same header, the same status line, the same two arrangements, over
// whichever rows and columns a source hands them. What a row *is* and which columns it has is the
// source's business; that they look the same is not.

/// The columns on one grid row per incident. The default, because it fits the most rows on a screen.
///
/// The column header is a section header rather than a view sitting outside the List. Outside, its
/// insets were my own guess and the rows' were the system's, so the two never quite lined up. In
/// here the system insets both identically, and a plain list keeps the header pinned while its rows
/// scroll.
///
/// The status line is in this header too, for the same reason one level up: it used to sit outside
/// the list above a hairline, at an inset that matched nothing below it.
struct CompactTableList<Row: Identifiable, Destination: View>: View {

    let rows: [Row]

    /// The columns to draw, in order. However many the source declares.
    let columns: [CompactColumn<Row>]

    let timeFormat: DispatchTimeFormat
    let status: FeedStatus

    /// Where a row goes when it is tapped. A source's own detail screen, since the fields are its
    /// own — the list draws whatever it is handed rather than assuming a destination.
    private let destination: (Row) -> Destination

    init(
        rows: [Row],
        columns: [CompactColumn<Row>],
        timeFormat: DispatchTimeFormat,
        status: FeedStatus,
        @ViewBuilder destination: @escaping (Row) -> Destination
    ) {
        self.rows = rows
        self.columns = columns
        self.timeFormat = timeFormat
        self.status = status
        self.destination = destination
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            Section {
                ForEach(rows) { row in
                    NavigationLink {
                        destination(row)
                    } label: {
                        CompactTableRow(row: row, columns: columns, timeFormat: timeFormat)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 6) {
                    FeedStatusLine(status: status)

                    // Above the accessibility text sizes the rows already show each field
                    // beside its own label, so a grid of column labels above them would be
                    // a second, contradictory copy of the same thing.
                    if !CompactTable.needsLabelledRows(dynamicTypeSize) {
                        CompactColumnHeader(columns: columns)
                    }
                }
            }
        }
        .listStyle(.plain)
        .softScrollEdge()
    }
}

/// The rows as blocks, in the platform's own list — the arrangement the Notes app and this app's
/// detail view both use.
///
/// **One `Section` for all of them, not one each.** That is the correction. A `Section` is
/// how the platform groups *related rows into one block*: the detail view has three of them
/// for three kinds of field, and each holds several rows. Giving every incident its own
/// section made a block holding a single row, which is not a group — it is a border, and a
/// screen of them reads as a wall of boxes rather than as a list. The block belongs around
/// the whole list, and the platform draws it: background, corner radius, insets, and the
/// hairlines between rows, inset from the leading edge exactly as Notes insets them.
///
/// A hand-rolled version of this — `.regularMaterial` in a `RoundedRectangle` with padding
/// picked by hand — was built and rejected for the same reason; see `CompactCardRow`.
///
/// **No `listStyle` is set, and that is deliberate.** The platform's default for a list of
/// sections is already this look, and it is what the detail view gets, where this
/// arrangement was asked to take its design from. Naming `.insetGrouped` would look
/// identical on iOS and fail to build for macOS, where that style is marked unavailable.
///
/// One consequence of the status line living here rather than above the list: section
/// headers in this style scroll away, where the old band stayed put. The line is context
/// for what you are reading, not a control, so scrolling with the content is the right
/// behaviour — but it is a change, and it is deliberate.
///
/// No column header. There are no columns.
struct CardsList<Row: Identifiable, Destination: View>: View {

    let rows: [Row]

    /// The columns in the order the card reads them: two per line.
    let columns: [CompactColumn<Row>]

    let timeFormat: DispatchTimeFormat
    let status: FeedStatus

    private let destination: (Row) -> Destination

    init(
        rows: [Row],
        columns: [CompactColumn<Row>],
        timeFormat: DispatchTimeFormat,
        status: FeedStatus,
        @ViewBuilder destination: @escaping (Row) -> Destination
    ) {
        self.rows = rows
        self.columns = columns
        self.timeFormat = timeFormat
        self.status = status
        self.destination = destination
    }

    var body: some View {
        List {
            Section {
                ForEach(rows) { row in
                    NavigationLink {
                        destination(row)
                    } label: {
                        CompactCardRow(row: row, columns: columns, timeFormat: timeFormat)
                    }
                }
            } header: {
                // The same line the table puts above its column labels. As a section header
                // the platform insets it to the block's leading edge, so it lines up with
                // the cards below instead of floating at an inset of its own.
                FeedStatusLine(status: status)
            }
        }
        .softScrollEdge()
    }
}
