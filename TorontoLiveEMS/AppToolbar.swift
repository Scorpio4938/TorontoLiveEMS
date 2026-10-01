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

/// The bar at the bottom of both screens: the switcher, and refresh.
///
/// **A safe-area inset rather than a toolbar**, and that is the whole point. Every bar this app
/// asked the platform for — a bottom-bar toolbar, the tab view's bottom accessory, a tab bar — has
/// either failed to draw or drawn and refused to respond. This one is *content*: it insets the
/// screen rather than claiming a placement, so it renders for the same reason the list renders.
///
/// It cannot collide with the tab bar either, which is what the last three attempts at this were
/// really about. When the tab bar draws, this bar stops being the only way to switch, and the
/// switcher can go back to being one.
///
/// A segmented `Picker` for the switch, not two buttons: the two screens are alternatives, and a
/// segmented control is what the platform uses to say so. Refresh stays bottom right, and keeps
/// its own definition — see `RefreshButton` for why it is now built rather than left to a bar.
struct ScreenSwitcherBar: View {

    @Binding var section: RootView.Section

    let model: IncidentFeedModel

    var body: some View {
        HStack(spacing: 12) {
            Picker("Screen", selection: $section) {
                ForEach(RootView.Section.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            RefreshButton(model: model)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

/// Refresh, as a view of its own.
///
/// Two places ask for it — the toolbar on macOS and the bar at the bottom on iOS — and they have
/// to agree about what it looks like. A button written twice is a button that drifts.
///
/// **Icon only, in a bordered button.** It used to be a plain labelled button inside a toolbar
/// item, and iOS 26 drew that as a circle; outside a toolbar, a plain labelled button is a word in
/// the accent colour, which is a red "Refresh" and not a button anybody recognised. So it is built
/// explicitly instead of relying on a bar to draw it.
///
/// `.bordered` with a square icon-only label is the circle, without naming a border shape —
/// `ButtonBorderShape.circle` is not in the SDK interface files I can check against, and a shape
/// guessed at is a build failed.
struct RefreshButton: View {

    let model: IncidentFeedModel

    var body: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
        // Not the accent. The accent is fire red, and a red button reads as an alarm about the
        // feed rather than as a control over it.
        .tint(.secondary)
    }
}
