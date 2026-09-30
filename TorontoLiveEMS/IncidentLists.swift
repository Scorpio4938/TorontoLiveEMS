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

/// One block per incident, formed by the platform.
///
/// A `Section` each, inside a grouped `List`, and nothing else. The block — background,
/// corner radius, insets, gaps — is the platform's, not ours, which is the whole point of
/// this arrangement. A hand-rolled version of it was built and rejected for exactly that
/// reason; see `IncidentCardRow`.
///
/// **No `listStyle` is set, and that is deliberate.** The platform's default for a list of
/// sections is already the grouped look — it is what the detail view gets, which is where
/// this arrangement was asked to take its blocks from. Naming `.insetGrouped` explicitly
/// would look identical on iOS and fail to build for macOS, where that style is marked
/// unavailable. Letting the platform choose is both the more Apple-native answer and the
/// portable one.
///
/// No column header. There are no columns.
struct CardsList: View {

    let incidents: [Incident]
    let timeFormat: DispatchTimeFormat

    var body: some View {
        List {
            ForEach(incidents) { incident in
                Section {
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
