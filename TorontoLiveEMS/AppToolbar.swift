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
        // One group, not several items sharing a placement. `ToolbarItemGroup` is the API for
        // more than one control in the same spot, and the order below is then the order on
        // screen — which is what keeps settings in the rightmost slot it has always had.
        ToolbarItemGroup(placement: .primaryAction) {
            // On iOS the refresh control is at the trailing end of the tab bar instead. Where
            // there is no tab bar to hold it, this is where it stays.
            #if !os(iOS)
            RefreshButton(onTap: onRefresh)
            #endif

            // **The same two controls the map tab floats, in the platform's own material.**
            //
            // `InfoControl` and `SettingsControl` are shared with the map capsule exactly —
            // symbol, size, colour, spacing and VoiceOver name — so nothing this app owns can
            // drift between the pages.
            //
            // The capsule around them is not shared, and hosting it here was tried and
            // reverted: a custom toolbar item is padded by the platform on top of whatever the
            // view already carries, so the controls came out *larger* than the map's, and the
            // wide item pushed the centred inline title off centre. That is the opposite of
            // what this was for. So the bar draws its own material around these same controls,
            // and the difference that keeps the two pages from being identical is who draws the
            // capsule — which is the platform's decision inside a bar, and not a number.
            InfoControl(action: onInfo)
            SettingsControl(action: onSettings)
        }
    }
}
