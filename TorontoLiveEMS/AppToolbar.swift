import SwiftUI

/// The refresh button, in whichever place the platform keeps it.
///
/// A view of its own because it appears in two: the top bar on the platforms that have no tab
/// bar to hold it, and — in `RootView` — as the trailing tab of the tab bar on iOS, where it is
/// a `Tab` rather than this. Both want the same plain labelled button, and one definition is
/// what stops them drifting.
///
/// **No button style, background or padding of its own**, so the platform draws it. It carried
/// a `.tint(.secondary)` for a while and a `.gray` after that; both were removed, because the
/// button was never the problem they were added to solve.
///
/// It takes a plain closure rather than an `async` one. The one place that knows a refresh is
/// asynchronous is the screen, which knows it needs a feed — so the `Task` is created there,
/// and this stays a button that calls something.
struct RefreshButton: View {

    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }
}

/// The controls every screen carries, declared once.
///
/// **Why this type exists.** Each tab in a `TabView` has its own `NavigationStack`, and
/// therefore its own navigation bar — so a toolbar is no longer a property of the app but of
/// each screen it appears on. Two screens now need the same controls, and this is the one
/// definition they both use, so they cannot drift apart in a corner of the screen nobody looks
/// at until it is wrong.
///
/// **The refresh control is not here on iOS.** It is a tab at the trailing end of the tab bar —
/// see `RootView`. A `.bottomBar` toolbar item was tried first and **does not merge**: it draws
/// as a second bar, of its own height, above the tab bar. That is now known rather than
/// assumed, because it was looked at on an iPhone.
struct AppToolbar: ToolbarContent {

    let onRefresh: () -> Void
    let onInfo: () -> Void
    let onSettings: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        // On iOS the refresh control is at the trailing end of the tab bar instead. Where there
        // is no tab bar to hold it, this is where it stays.
        #if !os(iOS)
        ToolbarItem(placement: .primaryAction) {
            RefreshButton(onTap: onRefresh)
        }
        #endif

        // **The same view the map tab floats, held by the bar instead.**
        //
        // `sharedBackgroundVisibility(.hidden)` is what makes one definition possible. Apple:
        // "Controls the visibility of the glass background effect on items in the toolbar…
        // toolbar items will be given a glass background effect that is shared with other items
        // in the same logical grouping", and hiding it "will cause the item to be placed in its
        // own grouping". So the bar places the item and `ScreenControls` draws the material —
        // the same material, the same shape, the same size, on both pages.
        //
        // What this replaced, and why it matters: the bar used to hold two `Button`s and draw
        // its own capsule around them. The map page drew its own capsule by hand. Two
        // implementations of the same two buttons, and no metric reconciles two renderers —
        // the bar decides its padding, its item spacing and its placement, and clamps what it
        // likes — which is why they still read a little apart however the numbers were set.
        //
        // `sharedBackgroundVisibility` is iOS 26 and macOS 26, and unavailable on visionOS,
        // which this target also declares. That branch keeps the platform's own buttons.
        #if os(iOS) || os(macOS)
        ToolbarItem(placement: .primaryAction) {
            ScreenControls(onInfo: onInfo, onSettings: onSettings)
        }
        .sharedBackgroundVisibility(.hidden)
        #else
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: onInfo) {
                Label("About this Data", systemImage: "info.circle")
            }

            Button(action: onSettings) {
                Label("Settings", systemImage: "gearshape")
            }
        }
        #endif
    }
}
