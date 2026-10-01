import SwiftUI

/// The app: two screens over one feed, and the bar that chooses between them.
///
/// **Not a `TabView` any more, and that is a concession rather than a design.** The platform's tab
/// bar has never drawn on this machine across six builds — with a bottom-bar toolbar, with the tab
/// view's bottom accessory, with neither, and with nothing but two `Text` views in it. Meanwhile
/// the *content* has always worked: the table renders, the rows navigate, the map draws.
///
/// So the switcher moved into the content, where rendering is not in question. That is a real
/// retreat from ADR-0005 — ask the platform first — and it is recorded as one: the platform was
/// asked, six times, and did not answer.
///
/// The tab bar goes back the moment it draws. `diagnose/tab-bar` on the remote is the branch that
/// asks whether it draws *at all*; if it does, this becomes a `TabView` again.
struct RootView: View {

    /// Which screen the switcher is showing.
    enum Section: String, CaseIterable, Identifiable {
        case incidents
        case map

        var id: String { rawValue }

        var title: String {
            switch self {
            case .incidents: "Incidents"
            case .map: "Map"
            }
        }

        var systemImage: String {
            switch self {
            case .incidents: "list.bullet"
            case .map: "map"
            }
        }
    }

    @State private var model = IncidentFeedModel()
    @State private var geocoder = IncidentGeocoder()

    @State private var section: Section = .incidents

    /// Which sheet is open, if any.
    ///
    /// One sheet driven by a value rather than two driven by booleans. Two `.sheet` modifiers on
    /// the same view is a long-standing way to get the first one working and the second silently
    /// not — and the symptom is exactly "the button does nothing", because the tap lands and the
    /// presentation does not.
    enum Sheet: String, Identifiable {
        case settings
        case aboutData

        var id: String { rawValue }
    }

    @State private var sheet: Sheet?

    var body: some View {
        // One screen at a time, rather than a container holding both. Each screen already carries
        // its own navigation stack and its own `.task`, so switching is a rebuild — which is
        // wanted: the map starts looking up locations when it appears, and does not when it does
        // not.
        Group {
            switch section {
            case .incidents:
                ContentView(
                    model: model,
                    geocoder: geocoder,
                    sheet: $sheet,
                    section: $section
                )
            case .map:
                IncidentsScreen(
                    model: model,
                    geocoder: geocoder,
                    sheet: $sheet,
                    section: $section
                )
            }
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .settings:
                SettingsView()
            case .aboutData:
                AboutThisDataView()
            }
        }
        // No alert. It was here, and an alert that is presented makes the whole window inert —
        // which was the symptom being chased for a while. The acknowledgement lives in the status
        // line instead, where it cannot block anything.
    }
}

/// The map, as a screen: a title bar, the controls both screens carry, and the map.
private struct IncidentsScreen: View {

    let model: IncidentFeedModel
    let geocoder: IncidentGeocoder

    /// The root's, not a second flag. Two screens each presenting their own would put one sheet
    /// behind the other, invisible and stuck.
    @Binding var sheet: RootView.Sheet?

    @Binding var section: RootView.Section

    var body: some View {
        NavigationStack {
            IncidentsMap(model: model, geocoder: geocoder)
                .navigationTitle("Map")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    AppToolbar(model: model, sheet: $sheet)
                }
                #if os(iOS)
                .safeAreaInset(edge: .bottom) {
                    ScreenSwitcherBar(section: $section, model: model)
                }
                #endif
        }
        // Here rather than on a container. A container's own `.task` is one task for everything
        // inside it and was not firing — the screens appeared and nothing loaded, while a manual
        // refresh worked. On the screens it is each view's own appearance, which is the thing that
        // is actually guaranteed.
        //
        // `loadIfEmpty` guards, so switching between the screens cannot fetch twice.
        .task {
            await model.loadIfEmpty()
        }
    }
}

#Preview {
    RootView()
}
