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
        // Refresh is not here on iOS. It is in the bar at the bottom of the screen, which is where
        // it belongs and where it was asked for.
        ToolbarItemGroup(placement: .primaryAction) {
            #if !os(iOS)
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

/// Refresh at the bottom right of a screen.
///
/// **`safeAreaInset`, not a toolbar and not the tab view's accessory.** Both of those claim the
/// bottom of the screen alongside the tab bar, and the bottom bar built that way took the tab
/// bar's place outright. This does not touch the tab bar at all: it insets the *content*, which is
/// the one way to put something at the bottom of the screen that cannot compete for the same
/// space.
///
/// It is a stopgap. `tabViewBottomAccessory` is the API meant for this — a control belonging to the
/// app rather than to a tab, drawn beside the tab bar — and it goes back there once the tab bar is
/// drawing at all, because until then there is nothing for it to sit beside.
struct RefreshBar: View {

    let model: IncidentFeedModel

    var body: some View {
        HStack {
            Spacer()
            RefreshButton(model: model)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
