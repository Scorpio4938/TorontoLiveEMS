import SwiftUI
import TorontoLiveEMSKit

/// The app: the feed, the chrome around it, and the screens it shows.
///
/// **Why this exists rather than the screen doing it all.** The title, the toolbar, the two
/// sheets and the alert are properties of the app rather than of any one screen — and the
/// screen that follows this one needs exactly the same chrome around different content. They
/// are gathered here so that adding a second screen is adding content, not copying plumbing.
///
/// **The feed is owned here, once.** Two screens read the same incidents and the same age for
/// them; a feed per screen would let them disagree about what is happening, which a reader
/// would never think to check.
struct RootView: View {

    @State private var feed = IncidentFeed()

    @State private var isShowingSettings = false
    @State private var isShowingAboutData = false
    @State private var isShowingNothingToUpdate = false

    var body: some View {
        NavigationStack {
            IncidentsPage(feed: feed)
                .navigationTitle("Active Incidents")
                #if os(iOS)
                // Inline rather than large. A large title collapses as the list scrolls while
                // the status line and column header below it stay pinned, so the chrome moves
                // in two directions at once. It also reserves a band of space above the title
                // that a table cannot afford. Inline sits on the same bar as the settings
                // button, rather than on a band above it, and does not move.
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    // One group, not several items sharing a placement. `ToolbarItemGroup` is
                    // the API for more than one control in the same spot, and the order below
                    // is then the order on screen — which is what keeps settings in the
                    // rightmost slot it has always had. Two separate `ToolbarItem`s would also
                    // put them side by side, but their left-to-right order would be something
                    // this code asserted rather than something it decided, and nothing here can
                    // check which it is.
                    ToolbarItemGroup(placement: .primaryAction) {
                        #if !os(iOS)
                        // On iOS this is in the bottom bar, where a thumb reaches it.
                        refreshButton
                        #endif
                        infoButton
                        settingsButton
                    }

                    #if os(iOS)
                    // The same plain toolbar item, in the system's bottom bar rather than the
                    // top one, and pushed to the trailing edge.
                    //
                    // `ToolbarSpacer` rather than a bare `Spacer()`. Both push the button over,
                    // but the first is the API for it — `@available(iOS 26.0, macOS 26.0, *)`,
                    // checked in the SDK's own interface, where a `Spacer` in a toolbar is a
                    // view that happens to have that effect.
                    //
                    // **A sibling of the group, not a child of it.** `ToolbarSpacer` conforms
                    // to `ToolbarContent` and not to `View`, and `ToolbarItemGroup`'s content
                    // is a `ViewBuilder` — so `ToolbarSpacer()` inside the braces does not
                    // compile: "generic struct 'ToolbarItemGroup' requires that
                    // 'ToolbarSpacer' conform to 'View'". It is a toolbar item in its own
                    // right, which is what makes it the API for this. The button needs a
                    // `ToolbarItem` of its own to go with it.
                    ToolbarSpacer(placement: .bottomBar)

                    ToolbarItem(placement: .bottomBar) {
                        refreshButton
                    }
                    #endif
                }
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
        }
        // Runs when the view appears. It deliberately does not run again when the app comes
        // back from the background: the previous result is still in memory, and the feed cannot
        // have changed more than once in five minutes anyway. The feed is an undocumented path
        // on the City's server, so the app asks for it only when it has nothing to show, or
        // when someone taps refresh.
        .task {
            if feed.snapshot == nil {
                await feed.load()
            }
        }
    }

    /// Unchanged from the original: a plain labelled button inside a toolbar item, with no
    /// button style, background or padding of its own, so the platform draws it.
    private var refreshButton: some View {
        Button {
            Task { await refresh() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }

    /// The same shape as the refresh button, in the platform's standard spot for it.
    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }

    /// What the fields mean, and where the data comes from. Reference material, so it is a
    /// button of its own rather than a row in Settings — somebody wondering what an Alarm Level
    /// is should not have to guess that it is filed under preferences.
    private var infoButton: some View {
        Button {
            isShowingAboutData = true
        } label: {
            Label("About this Data", systemImage: "info.circle")
        }
    }

    /// Refreshes, and says so when the City provably cannot have republished.
    ///
    /// The acknowledgement is an alert rather than a change to the status line, because the
    /// whole reason it exists is that a tap has to be visibly acknowledged — a silent skip is
    /// indistinguishable from a dead button.
    ///
    /// **Kept deliberately, and against advice.** An alert makes the whole window inert while
    /// it is up, which is itself indistinguishable from a dead button — the code comment that
    /// used to sit here said so. It survives this change so that the screen it sits beside is
    /// the only thing that differs; changing both at once would leave no way to say which one
    /// a failure belonged to. Whether it can fire at all, and what it does when it does, is
    /// #15 and #18.
    private func refresh() async {
        if await feed.refresh() == .skipped {
            isShowingNothingToUpdate = true
        }
    }
}

#Preview {
    RootView()
}
