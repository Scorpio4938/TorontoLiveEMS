import SwiftUI
import TorontoLiveEMSKit

/// The app: the feed, the screens, and the chrome around them.
///
/// **Two screens, and Apple's own control between them.** `TabView` and `Tab`, not a segmented
/// picker: a segmented control filters content rather than moving between places, and the tab
/// bar is what a reader already knows. It is also the control whose absence has been chased
/// six times, so it is worth saying why it was never there — a tab bar is at the bottom of the
/// screen on **iOS**, at the top on iPadOS, and a sidebar on macOS. Apple's own words for
/// `sidebarAdaptable`: *"iPadOS displays a top tab bar that can adapt into a sidebar. iOS
/// displays a bottom tab bar. macOS and tvOS always show a sidebar."* The record of where Xcode
/// had been pointed named an iPad simulator and a Mac, where a bottom tab bar has no reason to
/// exist. See `docs/design-decisions.md`, *The bar and the map page*.
///
/// **Refresh is a bottom-bar toolbar item, and whether that is right is unproven.** The request
/// is for the newer shape — the pages on one side of the bottom bar and a separate control at
/// the trailing edge of the same bar. `TabRole.prominent` is the API for that shape, new in
/// iOS 27, but the slot holds a **tab** and tapping it navigates; Music and Books put a search
/// *tab* there. A refresh cannot occupy it without becoming a page.
///
/// So the refresh control is a `.bottomBar` toolbar item instead, declared in `AppToolbar`.
/// Whether a bottom-bar toolbar renders as part of the tab bar or stacks above it **has never
/// been seen on an iPhone** — every earlier attempt used this arrangement and was run against
/// an iPad simulator, where a tab bar is at the top of the screen and none of it applied. That
/// is the thing to look at first.
///
/// **The feed is owned here, once.** Both screens read the same incidents and the same age for
/// them. A feed per screen could let them disagree about what is happening, which a reader
/// would never think to check — and the map's own author said so before this was rewritten.
struct RootView: View {

    @State private var feed = IncidentFeed()

    @State private var isShowingSettings = false
    @State private var isShowingAboutData = false
    @State private var isShowingNothingToUpdate = false

    var body: some View {
        tabs
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingAboutData) {
                AboutThisDataView()
            }
            .alert("Up to Date", isPresented: $isShowingNothingToUpdate) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(feed.nothingNewerMessage)
            }
            // Runs when the view appears. It deliberately does not run again when the app comes
            // back from the background: the previous result is still in memory, and the feed
            // cannot have changed more than once in five minutes anyway. The feed is an
            // undocumented path on the City's server, so the app asks for it only when it has
            // nothing to show, or when someone taps refresh.
            .task {
                if feed.snapshot == nil {
                    await feed.load()
                }
            }
    }

    private var tabs: some View {
        TabView {
            Tab("Incidents", systemImage: "list.bullet") {
                // Each tab carries its own `NavigationStack`, which is what gives it its own
                // title and its own navigation bar. That is the reason the toolbar is applied
                // here rather than once around the whole `TabView`.
                NavigationStack {
                    IncidentsPage(feed: feed)
                        .navigationTitle("Active Incidents")
                        .inlineNavigationTitle()
                        .toolbar { toolbar }
                }
            }

            Tab("Map", systemImage: "map") {
                NavigationStack {
                    IncidentsMapPage()
                        .navigationTitle("Map")
                        .inlineNavigationTitle()
                        .toolbar { toolbar }
                }
            }
        }
    }

    /// The controls both screens carry, from one definition.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        AppToolbar(
            onRefresh: refreshTapped,
            onInfo: { isShowingAboutData = true },
            onSettings: { isShowingSettings = true }
        )
    }

    /// The button knows nothing about tasks; this is the one place that does.
    private func refreshTapped() {
        Task { await refresh() }
    }

    /// Refreshes, and says so when the City provably cannot have republished.
    ///
    /// The acknowledgement is an alert rather than a change to the status line, because the
    /// whole reason it exists is that a tap has to be visibly acknowledged — a silent skip is
    /// indistinguishable from a dead button.
    ///
    /// **Kept deliberately, and against advice.** An alert makes the whole window inert while
    /// it is up, which is itself indistinguishable from a dead button; the comment that used to
    /// sit beside this said so. It survives this change so that the screen it sits beside is the
    /// only thing that differs — changing both at once would leave no way to say which one a
    /// failure belonged to. Whether it can fire at all, and what it does when it does, is #15
    /// and #18.
    private func refresh() async {
        if await feed.refresh() == .skipped {
            isShowingNothingToUpdate = true
        }
    }
}

private extension View {

    /// Inline on iOS, unchanged elsewhere.
    ///
    /// Inline rather than large, on iOS: a large title collapses as the list scrolls while the
    /// status line and column header below it stay pinned, so the chrome moves in two
    /// directions at once. It also reserves a band of space above the title that a table cannot
    /// afford. Inline sits on the same bar as the buttons, and does not move.
    ///
    /// `#if` inside a function body rather than at each call site, so the two screens cannot
    /// end up with different titles. The branches are resolved before type-checking, so the
    /// differing return types are not a problem.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

#Preview {
    RootView()
}
