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
        tabs
            // Refresh in the tab view's own bottom accessory, not in the top bar. On iOS 26 that
            // is the bar that sits *beside* the tab bar — the place Apple puts a control that
            // belongs to the whole app rather than to one tab, and the place this one was asked
            // for. It is a separate bar from the tabs, so the two do not compete for the bottom.
            #if os(iOS)
            .tabViewBottomAccessory {
                HStack {
                    Spacer()
                    RefreshButton(model: model)
                }
            }
            #endif
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingAboutData) {
                AboutThisDataView()
            }
            // A refresh the City provably cannot have changed is acknowledged rather than
            // silently skipped. A silent skip is indistinguishable from a dead button, which is
            // the fault this exists to answer.
            .alert("Up to Date", isPresented: $model.isUpToDate) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(model.upToDateMessage)
            }
    }

    private var tabs: some View {
        TabView {
            Tab("Active Incidents", systemImage: "list.bullet") {
                ContentView(
                    model: model,
                    geocoder: geocoder,
                    isShowingSettings: $isShowingSettings,
                    isShowingAboutData: $isShowingAboutData
                )
            }

            Tab("Map", systemImage: "map") {
                IncidentsScreen(
                    model: model,
                    geocoder: geocoder,
                    isShowingSettings: $isShowingSettings,
                    isShowingAboutData: $isShowingAboutData
                )
            }
        }
    }
}

/// The map, as a screen: a title bar, the controls both tabs carry, and the map.
private struct IncidentsScreen: View {

    let model: IncidentFeedModel
    let geocoder: IncidentGeocoder

    /// The root's flags, not a second pair. Two screens each owning their own would present the
    /// same sheet twice, and the one behind would be invisible and stuck.
    @Binding var isShowingSettings: Bool
    @Binding var isShowingAboutData: Bool

    var body: some View {
        NavigationStack {
            IncidentsMap(model: model, geocoder: geocoder)
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
