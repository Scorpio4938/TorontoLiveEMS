import SwiftUI

/// The controls both screens carry, in one place.
///
/// `ToolbarContent` rather than a view, because a toolbar takes toolbar content — and one
/// definition because two screens with the same buttons would otherwise be two chances to
/// disagree about their order, their placement, or whether refresh is among them.
struct AppToolbar: ToolbarContent {

    let model: IncidentFeedModel

    @Binding var sheet: RootView.Sheet?

    var body: some ToolbarContent {
        // The top bar, which is where the two buttons that open something live. One group, not
        // several items sharing a placement: `ToolbarItemGroup` is the API for more than one
        // control in the same spot, and the order below is then the order on screen — which is
        // what keeps settings in the rightmost slot it has always had.
        //
        // Refresh is deliberately not here on iOS. It is in the tab view's bottom accessory,
        // beside the tab bar, which is where a thumb reaches and what was asked for.
        ToolbarItemGroup(placement: .primaryAction) {
            #if !os(iOS)
            // macOS has no tab-view accessory, so there it is an ordinary toolbar item.
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
            sheet = .aboutData
        } label: {
            Label("About this Data", systemImage: "info.circle")
        }
    }

    private var settingsButton: some View {
        Button {
            sheet = .settings
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }
}

/// Refresh, as a view of its own.
///
/// Two places ask for it — the toolbar on macOS and the bottom accessory on iOS — and they have
/// to agree about what it looks like. A button written twice is a button that drifts.
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
