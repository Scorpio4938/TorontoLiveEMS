import SwiftUI
import TorontoLiveEMSKit

/// The app: the feeds, the screens, and the chrome around them.
///
/// **The app's sections, and Apple's own control between them.** `TabView` and `Tab`, not a segmented
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
/// **The feeds are owned here, once.** Every screen reads the same incidents and the same calls, and
/// the same age for them. A feed per screen could let them disagree about what is happening, which a
/// reader would never think to check — and the map's own author said so before this was rewritten.
struct RootView: View {

    /// Which page the bar is showing.
    ///
    /// Named `Screen` rather than `Section`, which is a SwiftUI type. The raw string matches
    /// `AppSection` for the four sections a launch can restore, with `refresh` as the one value that
    /// is chrome rather than a page.
    private enum Screen: String, Hashable {
        /// The app's index. The first launch opens here; a later launch opens here when Home was
        /// the last section.
        case home
        /// The fire feed's list. Named for the source rather than the content, because a police
        /// one is coming and two screens cannot both be called "Active Incidents".
        case fire
        /// The police incidents, which have no source yet. A screen of its own rather than a section
        /// of the fire one: when the data arrives it will be a second feed, not a second list.
        case police
        case map
        /// Not a page. See the refresh tab, which is put back the moment it is chosen.
        case refresh

        init(section: AppSection) {
            self = Screen(rawValue: section.rawValue) ?? .fire
        }

        /// The section this screen is, or `nil` for the refresh control.
        var section: AppSection? {
            AppSection(rawValue: rawValue)
        }
    }

    @State private var feed: IncidentFeed

    /// The screen during this run, fixed at launch and then changed by the tab bar.
    @State private var screen: Screen

    /// The police calls, owned here for the same reason the fire feed is: multiple screens reading
    /// two copies could disagree about what is happening, and about how current it is.
    ///
    /// The police page and the map load it on arrival; Home loads it too because Home shows its
    /// provenance line. The load itself belongs to whichever screen the reader has opened.
    @State private var policeFeed: PoliceCallFeed

    /// Which kind of map the map page draws.
    ///
    /// **Stored rather than passed.** Two views read it and neither owns the other: the page draws
    /// the map, and this view's chrome draws the control that changes it. A binding threaded from
    /// the app root into a page is exactly the plumbing this avoids — and it is the same pattern
    /// the dispatch-time format already uses, so nothing new is being invented to make it work.
    @AppStorage(SettingsKey.mapKind) private var mapKind: MapKind = .standard
    @AppStorage(SettingsKey.mapFilter) private var mapFilter: MapFilter = .all
    @AppStorage(SettingsKey.mapPoliceWindow) private var mapPoliceWindow: PoliceCallWindow = .oneHour

    /// The version this device last acknowledged.
    ///
    /// **Empty means this app has never been launched**, and that is the same emptiness the welcome
    /// greeting reads. Dismissing that greeting writes the bundle's version, which is what stops it
    /// appearing again.
    @AppStorage(SettingsKey.acknowledgedVersion) private var acknowledgedVersion = ""

    /// The last section the reader used, including Home.
    ///
    /// Written on every page change except the refresh control, and seeded on the way in with the
    /// section the launch opened on. A launch reads it through `LaunchBehaviour`.
    @AppStorage(SettingsKey.lastSection) private var lastSection: AppSection = .fire

    /// Whether Home is one of the tab bar's tabs. iOS only: the other platforms have no bottom
    /// tab bar, and their Home tab stays put.
    @AppStorage(SettingsKey.showsHomeTab) private var showsHomeTab = true

    /// Whether the leading house control is drawn while the tab is hidden.
    @AppStorage(SettingsKey.showsHomeButton) private var showsHomeButton = true

    @State private var isShowingSettings = false
    @State private var isShowingAboutData = false
    @State private var isShowingNothingToUpdate = false
    @State private var isShowingHome = false

    /// Whether the first-launch greeting is up.
    ///
    /// Decided once, at launch, from the stored version. It is false in a preview that supplies its
    /// own launch section. The Settings row can raise it again.
    @State private var isShowingWelcome: Bool

    /// Set by Settings when the reader asks to see the greeting again.
    ///
    /// The greeting is presented from `onDismiss`, once Settings has gone, so two sheets are never
    /// up at the same time.
    @State private var showsWelcomeAfterSettings = false

    /// Whether each tab's root page is the page on screen.
    ///
    /// The leading Home control lives in the shared top layer, like the trailing controls, so it
    /// cannot be attached to one page at a time. It must disappear when a detail is pushed and the
    /// navigation bar's back button takes the leading slot; a root's `onAppear`/`onDisappear` is
    /// how the shared layer knows.
    @State private var fireRootIsVisible = true
    @State private var policeRootIsVisible = true
    @State private var mapRootIsVisible = true

    /// The details presented above the map, as navigation-path values.
    ///
    /// **A path, not an appearance callback.** Pushing a detail appends its route at the tap, and
    /// popping it removes the route. The capsule reads this list, so it can shrink and grow with
    /// the navigation rather than waiting for a detail's `onDisappear`.
    @State private var mapPath: [MapRoute] = []

    /// The sentence the alert shows.
    ///
    /// Stored rather than worked out when the alert appears, because **which feed produced it is
    /// decided at the moment of the tap**: the reader can be on another tab by the time a fetch
    /// comes back, and an alert that described whatever tab they had moved to would be describing
    /// the wrong feed.
    @State private var nothingNewerMessage = ""

    /// Whether this instance may write the launch acknowledgement.
    ///
    /// True for the app, false for a preview that chose its own launch section. A preview that
    /// writes the real preference store would mark the developer's simulator as launched and make
    /// the next real launch skip Home.
    private let recordsLaunch: Bool

    /// The version whose release notes are being announced, or nil when nothing is declared.
    ///
    /// Copied from the newest CHANGELOG entry only when there is an announcement to make. Today
    /// nothing is declared: the first-launch greeting is the only content, and there is no What's
    /// New screen.
    private static let declaredWelcomeVersion: String? = nil

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
    ///
    /// `launchSection` is for previews and tests of the chrome: a preview should not inherit
    /// whatever this device last opened. The app leaves it `nil`, which reads the stored fact.
    init(
        feed: IncidentFeed,
        policeFeed: PoliceCallFeed,
        launchSection: AppSection? = nil
    ) {
        _feed = State(initialValue: feed)
        _policeFeed = State(initialValue: policeFeed)

        let storedVersion =
            UserDefaults.standard.string(forKey: SettingsKey.acknowledgedVersion) ?? ""
        let storedSection = UserDefaults.standard
            .string(forKey: SettingsKey.lastSection)
            .flatMap { AppSection(rawValue: $0) }
        let section = launchSection
            ?? LaunchBehaviour.section(
                acknowledgedVersion: storedVersion,
                lastUsed: storedSection
            )

        // A launch cannot select a tab that is not in the bar. If the reader has hidden Home and
        // Home is the stored last section, open Fire instead; the house control still reaches the
        // index. This is the one case where a stored Home is not restored.
        let initialSection: AppSection
        #if os(iOS)
        let storedShowsHomeTab = UserDefaults.standard
            .object(forKey: SettingsKey.showsHomeTab) as? Bool ?? true
        if launchSection == nil, !storedShowsHomeTab, section == .home {
            initialSection = .fire
        } else {
            initialSection = section
        }
        #else
        initialSection = section
        #endif

        _screen = State(initialValue: Screen(section: initialSection))

        let showsWelcome =
            launchSection == nil
            && WelcomeBehaviour.decision(
                storedVersion: storedVersion,
                declaredVersion: Self.declaredWelcomeVersion
            ) == .welcome
        _isShowingWelcome = State(initialValue: showsWelcome)
        recordsLaunch = launchSection == nil
    }

    /// Whether the capsule should show the map's own controls.
    ///
    /// The map tab alone is not enough: a detail pushed from the map is still on that tab, and four
    /// map controls over a detail is what this exists to stop. An empty path means the map is on top.
    private var showsMapControls: Bool {
        screen == .map && mapPath.isEmpty
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
                // The leading control is part of the same layer as Info and Settings. It is
                // present only on a root page, so a pushed detail keeps the back button.
                onHome: homeControlIsVisible ? { isShowingHome = true } : nil,
                onInfo: { isShowingAboutData = true },
                onSettings: { isShowingSettings = true },
                // **The map's controls belong only while the map is on top.** They are added to the
                // one shared layer at its leading end, so Info and Settings do not move when they
                // appear. A detail pushed from the map is still on the map tab, which is why the
                // condition is the navigation path rather than the tab alone.
                mapKind: showsMapControls ? $mapKind : nil,
                mapFilter: showsMapControls ? $mapFilter : nil,
                mapPoliceWindow: showsMapControls ? $mapPoliceWindow : nil
            )
            // The one greeting a fresh install gets. `onDismiss` is the acknowledgement: a swipe
            // and the Continue button land in the same place, so neither can leave it returning.
            .sheet(isPresented: $isShowingWelcome, onDismiss: acknowledgeWelcome) {
                WelcomeView()
            }
            .sheet(isPresented: $isShowingSettings, onDismiss: presentWelcomeIfRequested) {
                SettingsView(onShowWelcome: {
                    showsWelcomeAfterSettings = true
                })
            }
            // The index without a tab. The sheet is the price of hiding the tab, and it is
            // deliberately a sheet rather than a fifth tab that comes back while it is open:
            // the bar keeps the width the reader chose, and the house control is still the
            // way in.
            .sheet(isPresented: $isShowingHome) {
                NavigationStack {
                    HomePage(feed: feed, policeFeed: policeFeed)
                        .navigationTitle("Home")
                        .inlineNavigationTitle()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { isShowingHome = false }
                            }
                        }
                }
                .presentationDragIndicator(.visible)
            }
            // Which screen the info button opens is decided here rather than in the toolbar, because
            // there is one button and the answer is the data in front of the reader: the tab's, or
            // the source of the detail at the bottom of the map's navigation path. A sheet covers
            // the tab bar, so neither `screen` nor the path can move while this is up.
            .sheet(isPresented: $isShowingAboutData) {
                switch screen {
                case .police:
                    PoliceCallsInformationView()
                case .map:
                    if let source = mapPath.first?.source {
                        switch source {
                        case .fire:
                            AboutThisDataView()
                        case .police:
                            PoliceCallsInformationView()
                        }
                    } else {
                        MapInformationView()
                    }
                default:
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
            //
            // The launch leaves its opening section behind as the one to restore, and the welcome
            // sheet is what acknowledges the version. The version is deliberately not written here:
            // a greeting that was never dismissed must still be a first launch next time.
            .task {
                if recordsLaunch, let section = screen.section {
                    lastSection = section
                }
                if feed.snapshot == nil {
                    await feed.load()
                }
            }
    }

    private var tabs: some View {
        TabView(selection: $screen) {
            if homeTabIsShown {
                Tab("Home", systemImage: "house", value: Screen.home) {
                    NavigationStack {
                        HomePage(feed: feed, policeFeed: policeFeed)
                            .navigationTitle("Home")
                            .inlineNavigationTitle()
                            .barControls { toolbar }
                    }
                }
            }

            Tab("Fire", systemImage: "fire.extinguisher", value: Screen.fire) {
                // Each tab carries its own `NavigationStack`, which is what gives it its own
                // title and its own navigation bar. That is the reason the toolbar is applied
                // here rather than once around the whole `TabView`.
                NavigationStack {
                    FirePage(feed: feed)
                        .navigationTitle("Active Fire Incidents")
                        .inlineNavigationTitle()
                        .barControls { toolbar }
                        .onAppear { fireRootIsVisible = true }
                        .onDisappear { fireRootIsVisible = false }
                }
            }

            Tab("Police", systemImage: "shield", value: Screen.police) {
                NavigationStack {
                    PolicePage(feed: policeFeed)
                        .navigationTitle("Recent Police Incidents")
                        .inlineNavigationTitle()
                        .barControls { toolbar }
                        .onAppear { policeRootIsVisible = true }
                        .onDisappear { policeRootIsVisible = false }
                }
            }

            Tab("Map", systemImage: "map", value: Screen.map) {
                NavigationStack(path: $mapPath) {
                    IncidentsMapPage(feed: feed, policeFeed: policeFeed)
                        // **The detail route is a value in this stack's path.** The capsule reads
                        // the path, so a push shrinks it at the tap and a pop expands it as the
                        // detail leaves, rather than after an `onDisappear` callback.
                        .navigationDestination(for: MapRoute.self) { route in
                            switch route {
                            case .fire(let incident):
                                IncidentDetailView(incident: incident, feed: feed)
                            case .police(let call):
                                PoliceCallDetailView(call: call, policeFeed: policeFeed)
                            }
                        }
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
                        .onAppear { mapRootIsVisible = true }
                        .onDisappear { mapRootIsVisible = false }
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
        .onChange(of: homeTabIsShown) { _, shown in
            // Removing the tab while it is selected would leave the tab view pointing at
            // nothing. Fire is the launch fallback and the first page with content.
            if !shown, screen == .home {
                screen = .fire
            }
        }
        .onChange(of: screen) { previous, selected in
            if selected == .refresh {
                // Back to the tab they were on, **not** to Incidents. This read `.incidents` until
                // the map became a real page: refreshing while looking at the map would have moved
                // the reader somewhere else entirely. Put back first, because otherwise the refresh
                // would work exactly once — the second tap would not change the selection, so
                // nothing would change and nothing would fire. It is also why the bar's selection is
                // seen to move.
                screen = previous
                Task { await refresh() }
                return
            }

            // Every page is the last page, including Home. The only selection that is not a
            // section is the refresh control, which is not a place.
            if recordsLaunch, let section = selected.section {
                lastSection = section
            }
        }
    }

    /// Whether the Home tab is in the bar.
    ///
    /// The setting is iOS-only because the bottom tab bar is; the other platforms keep their
    /// Home tab regardless of a preference they cannot set.
    private var homeTabIsShown: Bool {
        #if os(iOS)
        showsHomeTab
        #else
        true
        #endif
    }

    /// Whether the leading Home control belongs in the shared top layer.
    ///
    /// It is absent when Home is still a tab, when the tab has no Home at all, and when the
    /// current tab is showing a pushed detail rather than its root. It is one question answered
    /// in one place, so Fire, Police and Map cannot style or place it differently.
    private var homeControlIsVisible: Bool {
        guard !homeTabIsShown, showsHomeButton else { return false }
        switch screen {
        case .home, .refresh:
            return false
        case .fire:
            return fireRootIsVisible
        case .police:
            return policeRootIsVisible
        case .map:
            return mapRootIsVisible
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

    /// The greeting is the acknowledgement, whether it was dismissed by Continue or by a swipe.
    private func acknowledgeWelcome() {
        guard recordsLaunch else { return }
        acknowledgedVersion = AppIdentity.marketingVersion
    }

    /// The Settings row asks for the greeting while Settings is still up. Present it only after
    /// that sheet has finished dismissing.
    private func presentWelcomeIfRequested() {
        guard showsWelcomeAfterSettings else { return }
        showsWelcomeAfterSettings = false
        isShowingWelcome = true
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
        case .home, .map:
            // **Both of these screens show both feeds, so a refresh on either asks both.** Fire can
            // still answer from the clock it holds, because the City's republish tick rides inside
            // the document it already fetched. The police half always asks the Service whether it has
            // written, and fetches the calls only when it has. A tap with nothing to fetch is still
            // instant.
            //
            // The alert only appears when **neither** found anything: saying "nothing newer" while one
            // of the two had in fact refreshed would be the kind of half-truth this alert exists to
            // avoid saying.
            let fireOutcome = await feed.refresh()
            let policeOutcome = await policeFeed.refresh()
            guard fireOutcome == .skipped, policeOutcome == .skipped else { return }
            outcome = .skipped
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
        onHome: (() -> Void)? = nil,
        onInfo: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        mapKind: Binding<MapKind>? = nil,
        mapFilter: Binding<MapFilter>? = nil,
        mapPoliceWindow: Binding<PoliceCallWindow>? = nil
    ) -> some View {
        #if os(iOS)
        overlay(alignment: .topTrailing) {
            ScreenControls(
                onInfo: onInfo,
                onSettings: onSettings,
                mapKind: mapKind,
                mapFilter: mapFilter,
                mapPoliceWindow: mapPoliceWindow
            )
                // Centred in a bar's height at a content margin, which is where the bar's own
                // items sat before this layer replaced them. The band height and the trailing inset
                // are the placement, and the only numbers in it.
                .frame(height: ScreenControls.bandHeight, alignment: .center)
                .padding(.trailing, 12)
        }
        .overlay(alignment: .topLeading) {
            if let onHome {
                HomeCapsule(action: onHome)
                    // The same band and leading inset as the trailing capsule, so the two are
                    // centred on the same line and cannot be placed differently per page.
                    .frame(height: ScreenControls.bandHeight, alignment: .center)
                    .padding(.leading, 12)
            }
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
        policeFeed: PreviewCalls.feed(),
        launchSection: .home
    )
}
