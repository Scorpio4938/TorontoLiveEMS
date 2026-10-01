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
        // Refresh is in the top bar on every platform, for now.
        //
        // It was moved to a bottom-bar toolbar on iOS, to a thumb's reach. That bar took the tab
        // bar's place — two things claiming the bottom of the screen — so it moved to the tab
        // view's bottom accessory, which is the API for exactly this. It is going back there. But
        // not in the same build as the bare tab view that has to prove the bar renders at all: one
        // change at a time is the whole lesson of the last three attempts, and refresh is known to
        // work here.
        ToolbarItemGroup(placement: .primaryAction) {
            RefreshButton(model: model)
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
