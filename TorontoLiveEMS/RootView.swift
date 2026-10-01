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
/// **Refresh occupies the tab bar's trailing slot, as a prominent tab.** The request was for the
/// shape Apple draws in Music and Books — the pages across the bar, and one control set apart at
/// its trailing end. That is `TabRole`, and `TabRole` has **exactly two properties**: `prominent`
/// (iOS 27) and `search` (iOS 18).
///
/// **`search` was tried first and renders as an ordinary third item.** Its documentation only
/// ever promised that a `.search` tab *"may receive the prominent visual treatment by default"*
/// — *may* — and `prominent` is the explicit request for it. That is the whole of the difference
/// between a third tab sitting flush in the bar and a control set apart at the end.
///
/// It is why `IPHONEOS_DEPLOYMENT_TARGET` is **27.0**: a `role:` argument cannot sit behind
/// `if #available`. The app is unreleased, so the cost is a number in the project file. The one
/// thing not yet known is what Apple means by *"in supported tab bars"* — the treatment may not
/// apply to every tab bar style, and on iPhone it may or may not break out the way Music's does.
///
/// Apple's own words for the slot: *"a tab bar can include a dedicated search **tab** at the
/// trailing end."*
///
/// **Which means it selects.** There is no action role, and no API for a tab-bar item that does
/// anything but navigate. So the tab sets the selection to `.refresh`, this code puts it back,
/// and the refresh happens in between. Two costs are real and are not being hidden: **the bar's
/// selection moves to the refresh tab and back on every tap**, and **VoiceOver is told it is a
/// tab** — true of the control, false of what it does. What that buys is one coherent bar,
/// instead of two bars of different heights, which is what the alternative actually looked like
/// on screen.
///
/// A `.bottomBar` toolbar item was tried before either of those and **does not merge**: it draws
/// as a second bar, of its own height, above the tab bar. That is now known from looking rather
/// than assumed.
///
/// **The feed is owned here, once.** Both screens read the same incidents and the same age for
/// them. A feed per screen could let them disagree about what is happening, which a reader
/// would never think to check — and the map's own author said so before this was rewritten.
struct RootView: View {

    /// Which page the bar is showing.
    ///
    /// Named `Screen` rather than `Section`, which is a SwiftUI type.
    private enum Screen: Hashable {
        case incidents
        case map
        /// Not a page. See the refresh tab, which is put back the moment it is chosen.
        case refresh
    }

    @State private var feed = IncidentFeed()
    @State private var screen: Screen = .incidents

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
        TabView(selection: $screen) {
            Tab("Incidents", systemImage: "list.bullet", value: Screen.incidents) {
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

            Tab("Map", systemImage: "map", value: Screen.map) {
                NavigationStack {
                    IncidentsMapPage(feed: feed)
                        .navigationTitle("Map")
                        .inlineNavigationTitle()
                        // **The bar draws no background, so the map shows through it.** On iOS 26 a
                        // navigation bar's background is Liquid Glass, which blurs and *tints*
                        // whatever is behind it — and behind this one is a map, so the tint takes
                        // the map's own colours. That is the band that was showing under the two
                        // buttons.
                        //
                        // The bar keeps its title and its buttons; only its surface goes. The two
                        // lists keep theirs, because a table under a bar wants the separation.
                        //
                        // This was applied once and then reverted on the strength of "it is still
                        // there", which is what a stale build looks like. It is the right API for
                        // this bar either way.
                        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                        .toolbar { toolbar }
                }
            }

            #if os(iOS)
            // The trailing control, set apart from the other two by the platform. It is a tab,
            // because a tab is the only thing this slot can hold.
            Tab("Refresh", systemImage: "arrow.clockwise", value: Screen.refresh, role: .prominent) {
                // Never meant to be seen: the selection is put back the instant it changes. It
                // has to have *some* content, and the incidents again is the honest choice — if
                // this ever is on screen, it does not claim to be a page of its own.
                NavigationStack {
                    IncidentsPage(feed: feed)
                        .navigationTitle("Active Incidents")
                        .inlineNavigationTitle()
                }
            }
            #endif
        }
        .onChange(of: screen) { previous, selected in
            guard selected == .refresh else { return }

            // Back to the tab they were on, **not** to Incidents. This read `.incidents` until
            // the map became a real page: refreshing while looking at the map would have moved
            // the reader somewhere else entirely. Put back first, because otherwise the refresh
            // would work exactly once — the second tap would not change the selection, so
            // nothing would change and nothing would fire. It is also why the bar's selection is
            // seen to move.
            screen = previous
            Task { await refresh() }
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
