import SwiftUI

/// The refresh button, in whichever place the platform keeps it.
///
/// A view of its own because it now appears in two: the accessory attached to the tab bar on
/// iOS, and the top bar everywhere else. Both want the same plain labelled button, and one
/// definition is what stops them drifting.
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
/// each screen it appears on. Two screens now need the same two buttons, and this is the one
/// definition they both use, so they cannot drift apart in a corner of the screen nobody looks
/// at until it is wrong.
///
/// Refresh is deliberately **absent on iOS**: it lives in the accessory attached to the tab bar
/// there, where a thumb reaches it, and a second copy at the top would be two controls for one
/// action.
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
    }
}
