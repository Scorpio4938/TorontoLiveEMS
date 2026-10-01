import SwiftUI

/// The controls both screens carry, in one place.
///
/// `ToolbarContent` rather than a view, because a toolbar takes toolbar content — and one
/// definition because two screens with the same three buttons would otherwise be two chances to
/// disagree about their order, their placement, or whether refresh is among them.
///
/// **Refresh is in the top bar on every platform now.** It used to be a bottom-bar item on iOS,
/// chosen when a thumb reaching it was the argument. The bottom belongs to the tab bar, and two
/// things claiming it is what "shouldn't conflict with the refresh button" was about.
struct AppToolbar: ToolbarContent {

    let model: IncidentFeedModel

    @Binding var isShowingSettings: Bool
    @Binding var isShowingAboutData: Bool

    var body: some ToolbarContent {
        // One group, not several items sharing a placement. `ToolbarItemGroup` is the API for
        // more than one control in the same spot, and the order below is then the order on
        // screen — which is what keeps settings in the rightmost slot it has always had.
        ToolbarItemGroup(placement: .primaryAction) {
            #if !os(iOS)
            // On iOS this is in the tab view's bottom accessory, where a thumb reaches it.
            RefreshButton(model: model)
            #endif
            infoButton
            settingsButton
        }
    }

    /// What the fields mean, and where the data comes from. Reference material, so it is a button
    /// of its own rather than a row in Settings — somebody wondering what an Alarm Level is
    /// should not have to guess that it is filed under preferences.
    private var infoButton: some View {
        Button {
            isShowingAboutData = true
        } label: {
            Label("About this Data", systemImage: "info.circle")
        }
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }
}

/// Refresh, as a view of its own.
///
/// Three places ask for it: the toolbar on macOS, the tab view's bottom accessory on iOS, and
/// nothing else — but the first two have to agree about what it looks like, and a button written
/// twice is a button that drifts.
///
/// A plain labelled button, with no button style, background or padding of its own, so the
/// platform draws it.
struct RefreshButton: View {

    let model: IncidentFeedModel

    var body: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }
}
