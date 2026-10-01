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
        ToolbarItemGroup(placement: .primaryAction) {
            #if !os(iOS)
            // On iOS this is in the bottom bar, where a thumb reaches it.
            RefreshButton(model: model)
            #endif
            infoButton
            settingsButton
        }

        #if os(iOS)
        // A bottom bar of its own. This is where refresh was from the beginning and how it
        // rendered — a circular button at the bottom right — and it is restored after a detour.
        //
        // The detour was mine and it was badly reasoned. I removed this because I decided it was
        // what had taken the tab bar's place, on the strength of it being plausible and the two
        // sharing a region. The tab bar did it not appearing before this existed, in the build
        // that used the tab view's bottom accessory instead — so this was never shown to be the
        // cause of anything, and I removed the one that worked.
        //
        // `ToolbarSpacer` is a sibling of the group, not a child of it. It conforms to
        // `ToolbarContent` and not to `View`, so inside a `ToolbarItemGroup` — whose content is a
        // `ViewBuilder` — it does not compile. It is a toolbar item in its own right, which is
        // what makes it the API for this and a bare `Spacer` only a view that has the effect.
        ToolbarSpacer(placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            RefreshButton(model: model)
        }
        #endif
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
