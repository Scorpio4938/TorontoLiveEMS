import SwiftUI
import TorontoLiveEMSKit

// The active incidents, arranged the way the reader chose.
//
// Both arrangements are views of their own rather than private methods of the screen,
// because the previews have to render the real ones. A preview that draws its own copy can
// disagree with the app, and two views disagreeing about a column layout is exactly what
// broke the header alignment twice.

/// Five fields on one grid row per incident. The default, because it fits the most
/// incidents on a screen.
///
/// The column header is a section header rather than a view sitting outside the List.
/// Outside, its insets were my own guess and the rows' were the system's, so the two never
/// quite lined up. In here the system insets both identically, and a plain list keeps the
/// header pinned while its rows scroll.
struct CompactTableList: View {

    let incidents: [Incident]
    let timeFormat: DispatchTimeFormat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            Section {
                ForEach(incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident)
                    } label: {
                        IncidentRow(incident: incident, timeFormat: timeFormat)
                    }
                }
            } header: {
                // Above the accessibility text sizes the rows already show each field
                // beside its own label, so a grid of column labels above them would be a
                // second, contradictory copy of the same thing.
                if !CompactTable.needsLabelledRows(dynamicTypeSize) {
                    CompactColumnHeader()
                }
            }
        }
        .listStyle(.plain)
    }
}

/// The incidents as rows, in the platform's own list — the arrangement the Notes app and
/// this app's detail view both use.
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
/// picked by hand — was built and rejected for the same reason; see `IncidentCardRow`.
///
/// **No `listStyle` is set, and that is deliberate.** The platform's default for a list of
/// sections is already this look, and it is what the detail view gets, where this
/// arrangement was asked to take its design from. Naming `.insetGrouped` would look
/// identical on iOS and fail to build for macOS, where that style is marked unavailable.
///
/// No column header. There are no columns.
struct CardsList: View {

    let incidents: [Incident]
    let timeFormat: DispatchTimeFormat

    var body: some View {
        List {
            Section {
                ForEach(incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident)
                    } label: {
                        IncidentCardRow(incident: incident, timeFormat: timeFormat)
                    }
                }
            }
        }
    }
}
