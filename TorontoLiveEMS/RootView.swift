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
        /// The fire feed's list. Named for the source rather than the content, because a police
        /// one is coming and two screens cannot both be called "Active Incidents".
        case fire
        /// The police incidents, which have no source yet. A screen of its own rather than a section
        /// of the fire one: when the data arrives it will be a second feed, not a second list.
        case police
        case map
        /// Not a page. See the refresh tab, which is put back the moment it is chosen.
        case refresh
    }

    @State private var feed: IncidentFeed
    @State private var screen: Screen = .fire

    /// The police calls, owned here for the same reason the fire feed is: two screens reading two
    /// copies could disagree about what is happening, and about how current it is.
    ///
    /// It is read when the reader opens the police tab rather than at launch — nothing else shows
    /// these calls — and that load lives on the page.
    @State private var policeFeed: PoliceCallFeed

    /// Which kind of map the map page draws.
    ///
    /// **Stored rather than passed.** Two views read it and neither owns the other: the page draws
    /// the map, and this view's chrome draws the control that changes it. A binding threaded from
    /// the app root into a page is exactly the plumbing this avoids — and it is the same pattern
    /// the dispatch-time format already uses, so nothing new is being invented to make it work.
    @AppStorage(SettingsKey.mapKind) private var mapKind: MapKind = .standard

    @State private var isShowingSettings = false
    @State private var isShowingAboutData = false
    @State private var isShowingNothingToUpdate = false

    /// The sentence the alert shows.
    ///
    /// Stored rather than worked out when the alert appears, because **which feed produced it is
    /// decided at the moment of the tap**: the reader can be on another tab by the time a fetch
    /// comes back, and an alert that described whatever tab they had moved to would be describing
    /// the wrong feed.
    @State private var nothingNewerMessage = ""

    /// The feed is taken rather than made, so a preview can hand the app a fixed snapshot and
    /// never touch the City's server.
    ///
    /// **This is what makes the whole app previewable.** Without it, `#Preview` could only ever
    /// build a live feed and sit on "Loading active incidents" — which meant every look at the
    /// chrome above these two screens, and every experiment on it, cost a full build and a
    /// device.
    ///
    /// **No default value, deliberately.** `IncidentFeed` is `@MainActor`, and a default
    /// argument is evaluated in a nonisolated context, so `= IncidentFeed()` does not compile:
    /// "call to main actor-isolated initializer 'init(fetch:now:)' in a synchronous nonisolated
    /// context". Every caller here — the app entry point and the preview — is already a main
    /// actor context, so they can pass it themselves. Found by the compiler, not by thinking.
    init(feed: IncidentFeed, policeFeed: PoliceCallFeed) {
        _feed = State(initialValue: feed)
        _policeFeed = State(initialValue: policeFeed)
    }

    var body: some View {
        tabs
            // **The app's controls, drawn once, above both pages.**
            //
            // The tab bar is the model. It is not part of either page — the container draws it —
            // and that is exactly why it cannot differ between them. These two controls are now
            // the same thing at the other end of the screen: one declaration, one position, one
            // rendering, over whichever page is showing, and over a pushed detail view as well.
            //
            // Why not an accessory: the platform has none at the top. `tabViewBottomAccessory`
            // is the only one, and it is the bottom. An overlay on the tab view is the
            // container-level layer, and the safe area it respects is the tab view's own — the
            // status bar on iPhone, and on iPad the top tab bar, so the controls land below it
            // rather than on top of it.
            //
            // What this replaces: each page hosting a toolbar item, which could not be made to
            // match, because a bar draws its items itself and pads what it is given. The bar
            // keeps the title, which was never the part in question.
            .screenControlsLayer(
                onInfo: { isShowingAboutData = true },
                onSettings: { isShowingSettings = true },
                // **The belief under test.** The map's own control is *added* to the one shared
                // layer, on the one tab that has a map, rather than being a second piece of chrome.
                // `screen` is the tab view's own selection, so the condition needs no new state —
                // and the control goes at the capsule's leading end, so Info and Settings do not
                // move when it appears.
                mapKind: screen == .map ? $mapKind : nil
            )
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            // Which screen the info button opens is decided here rather than in the toolbar, because
            // there is one button and two answers: the reader is looking at a tab, and the
            // information they want is that tab's. A sheet covers the tab bar, so `screen` cannot
            // move while this is up.
            .sheet(isPresented: $isShowingAboutData) {
                if screen == .police {
                    PoliceCallsInformationView(
                        callTypes: PoliceCallType.published(in: policeFeed.calls ?? [])
                    )
                } else {
                    AboutThisDataView()
                }
            }
            .alert("Up to Date", isPresented: $isShowingNothingToUpdate) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(nothingNewerMessage)
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
            Tab("Fire", systemImage: "fire.extinguisher", value: Screen.fire) {
                // Each tab carries its own `NavigationStack`, which is what gives it its own
                // title and its own navigation bar. That is the reason the toolbar is applied
                // here rather than once around the whole `TabView`.
                NavigationStack {
                    FirePage(feed: feed)
                        .navigationTitle("Active Fire Incidents")
                        .inlineNavigationTitle()
                        .barControls { toolbar }
                }
            }

            Tab("Police", systemImage: "shield", value: Screen.police) {
                NavigationStack {
                    PolicePage(feed: policeFeed)
                        .navigationTitle("Recent Police Incidents")
                        .inlineNavigationTitle()
                        .barControls { toolbar }
                }
            }

            Tab("Map", systemImage: "map", value: Screen.map) {
                NavigationStack {
                    IncidentsMapPage(feed: feed)
                        // **The map tab has no navigation bar.** The band under it was the bar's
                        // own glass — the build that hid the bar proved it — so the bar stays
                        // hidden and the page is named by floating text instead.
                        //
                        // The two controls are not here at all. They are drawn once above every
                        // page by `screenControlsLayer` on the tab view, which is the only
                        // arrangement that can be identical on a page with a bar and a page
                        // without one.
                        //
                        // The title and toolbar below are inert on iOS — there is no bar to hold
                        // them — but not unused elsewhere: `barControls` applies them where the
                        // platform has no layer above the pages, and a detail view pushed from
                        // here takes a back button labelled "Map".
                        .navigationTitle("Map")
                        .inlineNavigationTitle()
                        .toolbar(.hidden, for: .navigationBar)
                        .barControls { toolbar }
                        .overlay(alignment: .top) { mapTitle }
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
                    FirePage(feed: feed)
                        .navigationTitle("Active Fire Incidents")
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

    /// The controls, where the platform's own bar holds them.
    ///
    /// Unused on iOS: the controls are drawn once above every page instead — see
    /// `screenControlsLayer` — which is the only arrangement that can be identical on a page with
    /// a bar and a page without one.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        AppToolbar(
            onRefresh: refreshTapped,
            onInfo: { isShowingAboutData = true },
            onSettings: { isShowingSettings = true }
        )
    }

    /// The map tab's name, floating: the tab has no navigation bar, and this is what carries the
    /// page's name instead. Plain text, centred, where the bar's inline title used to sit. Its
    /// first floating version was a glass capsule like the controls', and that read as a button —
    /// a capsule is a control's shape, and the title is a name, not a control.
    private var mapTitle: some View {
        Text("Map")
            .font(.headline)
            .padding(.top, 12)
    }

    /// The button knows nothing about tasks; this is the one place that does.
    private func refreshTapped() {
        Task { await refresh() }
    }

    /// Refreshes the feed of the tab the reader is on, and says so when there is provably nothing
    /// newer.
    ///
    /// **One control above every tab, so it has to mean the tab it was tapped on.** It used to
    /// refresh the fire feed wherever it was tapped. On the police tab that re-read the City's fire
    /// data, left the calls exactly where they were, and — when the City had not republished — put
    /// "Up to Date" over a screen of police calls. That is not a dead button, which is the failure
    /// the alert was written to avoid; it is a false reassurance, which is worse.
    ///
    /// `screen` is read here rather than passed in, because both ways of asking have already put it
    /// right: the prominent tab restores the previous selection *before* it runs its task (see the
    /// note there), and the toolbar's button is only ever tapped while its own page is on screen.
    ///
    /// The acknowledgement is an alert rather than a change to the status line, because the whole
    /// reason it exists is that a tap has to be visibly acknowledged — a silent skip is
    /// indistinguishable from a dead button. **Kept deliberately, and against advice:** an alert
    /// makes the whole window inert while it is up, which is itself indistinguishable from a dead
    /// button. What #15 and #18 were about was what it says and whether it is ever true; both tabs
    /// now answer a refresh with a fact, so both can say this honestly.
    private func refresh() async {
        let outcome: RefreshOutcome
        let message: String

        switch screen {
        case .police:
            outcome = await policeFeed.refresh()
            message = policeFeed.nothingNewerMessage
        default:
            outcome = await feed.refresh()
            message = feed.nothingNewerMessage
        }

        guard outcome == .skipped else {
            return
        }
        nothingNewerMessage = message
        isShowingNothingToUpdate = true
    }
}

private extension View {

    /// The app's controls, drawn once above every page.
    ///
    /// **The tab bar's arrangement, at the other end of the screen.** One declaration, one
    /// position, one rendering, above whichever page is showing — so a page with a navigation bar
    /// and a page without one cannot differ, which is the whole of what was being chased.
    ///
    /// iOS only, because the bar behaviour this exists to avoid is an iOS bar's: on the other
    /// platforms the window toolbar has the controls already, applied by `barControls`. The `#if`
    /// is inside the body rather than at each call site, so the tabs cannot end up with different
    /// chrome.
    @ViewBuilder
    func screenControlsLayer(
        onInfo: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        mapKind: Binding<MapKind>? = nil
    ) -> some View {
        #if os(iOS)
        overlay(alignment: .topTrailing) {
            ScreenControls(onInfo: onInfo, onSettings: onSettings, mapKind: mapKind)
                // Centred in a bar's height at a content margin, which is where the bar's own
                // items sat before this layer replaced them. These two numbers are the placement,
                // and the only ones in it.
                .frame(height: 44, alignment: .center)
                .padding(.trailing, 12)
        }
        #else
        self
        #endif
    }

    /// The bar's own controls, on the platforms that have no layer above the pages.
    @ViewBuilder
    func barControls<Content: ToolbarContent>(
        @ToolbarContentBuilder _ content: () -> Content
    ) -> some View {
        #if os(iOS)
        self
        #else
        toolbar(content)
        #endif
    }

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

#Preview("App — sample data") {
    RootView(
        feed: IncidentFeed(fetch: { PreviewIncidents.snapshot }),
        policeFeed: PreviewCalls.feed()
    )
}
