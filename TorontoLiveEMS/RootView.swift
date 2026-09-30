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

    @State private var isShowingSettings = false
    @State private var isShowingAboutData = false

    var body: some View {
        TabView {
            Tab("Active Incidents", systemImage: "list.bullet") {
                ContentView(
                    model: model,
                    isShowingSettings: $isShowingSettings,
                    isShowingAboutData: $isShowingAboutData
                )
            }

            Tab("Map", systemImage: "map") {
                IncidentsScreen(
                    model: model,
                    isShowingSettings: $isShowingSettings,
                    isShowingAboutData: $isShowingAboutData
                )
            }
        }
        // One load for both tabs. It deliberately does not run again when the app comes back from
        // the background: the previous result is still in memory, and the feed cannot have changed
        // more than once in five minutes anyway. The feed is an undocumented path on the City's
        // server, so the app asks for it only when it has nothing to show, or when someone taps
        // refresh.
        // In the environment rather than passed down. Three views use it and they are four
        // levels apart; threading it through the ones in between would give four chances to
        // forget, and it is app-wide state in any case — an incident looked up on one screen
        // should be known on the other.
        .environment(geocoder)
        .task {
            await model.loadIfEmpty()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingAboutData) {
            AboutThisDataView()
        }
        // A refresh that the City provably cannot have changed is acknowledged rather than
        // silently skipped. A silent skip is indistinguishable from a dead button, which is the
        // fault this exists to answer.
        .alert("Up to Date", isPresented: $model.isUpToDate) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(model.upToDateMessage)
        }
    }
}

/// The map, as a screen: a title bar, the controls both tabs carry, and the map.
private struct IncidentsScreen: View {

    let model: IncidentFeedModel

    /// The root's flags, not a second pair. Two screens each owning their own would present the
    /// same sheet twice, and the one behind would be invisible and stuck.
    @Binding var isShowingSettings: Bool
    @Binding var isShowingAboutData: Bool

    var body: some View {
        NavigationStack {
            IncidentsMap(model: model)
                .navigationTitle("Map")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    AppToolbar(
                        model: model,
                        isShowingSettings: $isShowingSettings,
                        isShowingAboutData: $isShowingAboutData
                    )
                }
        }
    }
}

#Preview {
    RootView()
}
