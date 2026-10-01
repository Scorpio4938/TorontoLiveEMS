import SwiftUI

/// The refresh button, in whichever place the platform keeps it.
///
/// A view of its own because it appears in two: the bottom bar on iOS, and the top bar on the
/// platforms that have no tab bar to put it beside. Both want the same plain labelled button,
/// and one definition is what stops them drifting.
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
/// **Refresh is a `.bottomBar` item on iOS, and what that does is an open question.** The
/// request is for the newer shape: the pages on one side of the bottom bar and a separate
/// control at the trailing edge of *the same bar*. `TabRole.prominent` is the API for that
/// shape — `@available(iOS 27.0)`, "prominent visual treatment to one of the tabs in supported
/// tab bars" — but the slot holds a **tab**, so tapping it navigates. That is what Music and
/// Books put there: a search tab. A refresh button cannot go in that slot without becoming a
/// page you have to leave again.
///
/// So this is the other candidate: a bottom-bar toolbar item beside the tab bar. Whether the
/// two render as one bar or the toolbar stacks above it **has never been seen on an iPhone** —
/// every earlier attempt used this and was run on an iPad simulator, where the tab bar is at the
/// top of the screen and none of it applied. `ToolbarSpacer` pushes the button to the trailing
/// edge, which is where the request puts it.
struct AppToolbar: ToolbarContent {

    let onRefresh: () -> Void
    let onInfo: () -> Void
    let onSettings: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        // One group, not several items sharing a placement. `ToolbarItemGroup` is the API for
        // more than one control in the same spot, and the order below is then the order on
        // screen — which is what keeps settings in the rightmost slot it has always had. Two
        // separate `ToolbarItem`s would also put them side by side, but their left-to-right
        // order would be something this code asserted rather than something it decided, and
        // nothing here can check which it is.
        ToolbarItemGroup(placement: .primaryAction) {
            // On iOS the refresh control is in the bottom bar instead. On the platforms where
            // there is no tab bar to share that space with, this is where it stays.
            #if !os(iOS)
            RefreshButton(onTap: onRefresh)
            #endif

            // What the fields mean, and where the data comes from. Reference material, so it is
            // a button of its own rather than a row in Settings — somebody wondering what an
            // Alarm Level is should not have to guess that it is filed under preferences.
            Button(action: onInfo) {
                Label("About this Data", systemImage: "info.circle")
            }

            Button(action: onSettings) {
                Label("Settings", systemImage: "gearshape")
            }
        }

        #if os(iOS)
        // `ToolbarSpacer` rather than a bare `Spacer()`. Both push the button over, but the
        // first is the API for it — `@available(iOS 26.0, macOS 26.0, *)`, checked in the SDK's
        // own interface, where a `Spacer` in a toolbar is a view that happens to have that
        // effect.
        //
        // **A sibling of the group, not a child of it.** `ToolbarSpacer` conforms to
        // `ToolbarContent` and not to `View`, and `ToolbarItemGroup`'s content is a
        // `ViewBuilder` — so `ToolbarSpacer()` inside the braces does not compile: "generic
        // struct 'ToolbarItemGroup' requires that 'ToolbarSpacer' conform to 'View'". It is a
        // toolbar item in its own right, which is what makes it the API for this. The button
        // needs a `ToolbarItem` of its own to go with it.
        ToolbarSpacer(placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            RefreshButton(onTap: onRefresh)
        }
        #endif
    }
}
