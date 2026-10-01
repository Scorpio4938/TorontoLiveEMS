import SwiftUI

/// The app: two screens over one feed.
///
/// A `TabView`, because that is what the platform calls two peer sections of an app — and a
/// segmented picker would be the wrong tool twice over: it filters content rather than navigating
/// between places, and with two tabs the tab bar is what a reader already knows.
///
/// The feed and the geocoder live here rather than in either tab, because both tabs show the same
/// incidents. A map that fetched separately from the list could disagree with it about what is
/// happening, and a reader would have no way to tell which one was wrong.
struct RootView: View {

    @State private var model = IncidentFeedModel()
    @State private var geocoder = IncidentGeocoder()

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
        // **Nothing on the tab view but the tabs.** This is deliberate and it is temporary.
        //
        // Three attempts at putting a control at the bottom of this screen have failed, and each
        // one changed several things at once — a bottom-bar toolbar, a bottom accessory, a
        // bar-minimising style — so that when the tab bar did not appear there was no way to say
        // which of them was responsible. This is the version that answers that: the switcher, and
        // nothing else, so that if the bar renders now, the platform was never the problem and
        // whatever suppressed it is one of the things removed here.
        //
        // Refresh has moved to the top bar, where it was before any of this, for the same reason —
        // it is known to work there, so the switcher is the only variable. The bottom accessory
        // comes back on its own ticket once this is confirmed.
        tabs
            .sheet(item: $sheet) { which in
                switch which {
                case .settings:
                    SettingsView()
                case .aboutData:
                    AboutThisDataView()
                }
            }
            // No alert. It was here, and an alert that is presented makes the whole window
            // inert — which is exactly the symptom being chased: every button visible, every
            // button doing nothing. Until it is known whether that was the cause, the
            // acknowledgement lives in the status line, where it cannot block anything.
    }

    private var tabs: some View {
        TabView {
            Tab("Active Incidents", systemImage: "list.bullet") {
                ContentView(model: model, geocoder: geocoder, sheet: $sheet)
            }

            Tab("Map", systemImage: "map") {
                IncidentsScreen(model: model, geocoder: geocoder, sheet: $sheet)
            }
        }
    }
}

/// The map, as a screen: a title bar, the controls both tabs carry, and the map.
private struct IncidentsScreen: View {

    let model: IncidentFeedModel
    let geocoder: IncidentGeocoder

    /// The root's, not a second flag. Two screens each presenting their own would put one sheet
    /// behind the other, invisible and stuck.
    @Binding var sheet: RootView.Sheet?

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
        }
        // Here rather than on the tab view. A `TabView`'s own `.task` is one task for the whole
        // container and was not firing — the screens appeared and nothing loaded, while a manual
        // refresh worked. On the screens it is each view's own appearance, which is the thing
        // that is actually guaranteed.
        //
        // `loadIfEmpty` guards, so the two tabs cannot both fetch and cannot fetch twice.
        .task {
            await model.loadIfEmpty()
        }
    }
}

#Preview {
    RootView()
}
