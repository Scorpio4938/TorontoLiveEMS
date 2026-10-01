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

/// The bar at the bottom of both screens: the sections, and refresh beside them.
///
/// **Shaped like the iOS 26 bottom bar — Books, App Store, Music.** One floating capsule of glass
/// holding the sections, and a separate circular glass button to its right. Same material, separate
/// containers, which is the part that took two attempts to get right.
///
/// **The first attempt built two different glasses.** The sections sat in an `HStack` with
/// `glassEffect` applied by hand, and refresh was a `Button` with `buttonStyle(.glass)` — two
/// separate effects, rendered separately, and they came out looking like two different materials.
/// The screenshot said so before I could work it out from the code.
///
/// Apple's own description of `GlassEffectContainer` is the fix: *"a view that combines multiple
/// Liquid Glass shapes into a single shape… as shapes near one another, their paths start to blend
/// into one another"*, and the container's `spacing` sets how soon that begins. So every element in
/// this bar is a `.glass` button — one mechanism, not two — and they all live in one container. The
/// sections sit 8 points apart inside a container spaced at 24, so their shapes blend into the
/// single capsule a tab bar is. Refresh is pushed to the far side by a `Spacer`, so it stays its
/// own circle — which is what the reference apps do.
///
/// **Still a safe-area inset rather than a toolbar.** Every bar this app asked the platform to draw
/// — a bottom-bar toolbar, the tab view's bottom accessory, a tab bar — either failed to appear or
/// appeared and refused to respond. This one is *content*: it insets the screen rather than claiming
/// a placement, so it renders for the same reason the list renders.
///
/// Glass is `@available(…, visionOS unavailable)`, and this target builds for `xros`, so the
/// container and the styles are guarded and everything else falls back to ordinary buttons.
struct ScreenSwitcherBar: View {

    @Binding var section: RootView.Section

    let model: IncidentFeedModel

    var body: some View {
        #if os(iOS) || os(macOS)
        // One container for the whole bar. This is what makes the pieces one material.
        GlassEffectContainer(spacing: 24) {
            bar
        }
        #else
        bar
        #endif
    }

    /// The bar's contents. `spacing: 8` between the sections is inside the container's 24, which is
    /// the ratio that lets their glass merge into one capsule rather than sitting as two blobs.
    private var bar: some View {
        HStack(spacing: 8) {
            ForEach(RootView.Section.allCases) { candidate in
                sectionButton(for: candidate)
            }

            Spacer(minLength: 0)

            RefreshButton(model: model)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    /// Both states are the same glass, at two weights — prominent for the section being shown. That
    /// is what the platform does with a selected tab, and it is why the selected one takes the
    /// app's tint while its neighbours do not.
    @ViewBuilder
    private func sectionButton(for candidate: RootView.Section) -> some View {
        if candidate == section {
            Button {
                section = candidate
            } label: {
                label(for: candidate)
            }
            #if os(iOS) || os(macOS)
            .buttonStyle(.glassProminent)
            #else
            .buttonStyle(.borderedProminent)
            #endif
        } else {
            Button {
                section = candidate
            } label: {
                label(for: candidate)
            }
            #if os(iOS) || os(macOS)
            .buttonStyle(.glass)
            #else
            .buttonStyle(.bordered)
            #endif
        }
    }

    /// Icon over title, which is how the platform lays out a tab.
    private func label(for candidate: RootView.Section) -> some View {
        VStack(spacing: 2) {
            Image(systemName: candidate.systemImage)
            Text(candidate.title)
                .font(.caption2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(minWidth: 68)
    }
}

/// Refresh, as a view of its own.
///
/// Two places ask for it — the toolbar on macOS and the bar at the bottom on iOS — and they have
/// to agree about what it looks like. A button written twice is a button that drifts.
///
/// **Icon only, in a glass button.** It used to be a plain labelled button inside a toolbar item,
/// and iOS 26 drew that as a circle; outside a toolbar, a plain labelled button is a word in the
/// accent colour, which is a red "Refresh" and not a button anybody recognised. So it is built
/// explicitly instead of relying on a bar to draw it.
///
/// Glass, because that is the material of the separate circular button in every one of the apps
/// this design is taken from — Books, App Store, Music. An icon-only label inside a glass button
/// is the circle, without naming a border shape: `ButtonBorderShape.circle` is not in the SDK
/// interface files available here, and a shape guessed at is a build failed.
struct RefreshButton: View {

    let model: IncidentFeedModel

    var body: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
                .labelStyle(.iconOnly)
        }
        // Glass where it exists — the circular button beside the bar in every one of the apps
        // this is modelled on. Unavailable on visionOS, which this target builds for; see
        // `ScreenSwitcherBar` for the same guard and the same reason.
        #if os(iOS) || os(macOS)
        .buttonStyle(.glass)
        #else
        .buttonStyle(.bordered)
        #endif
        // Not the accent. The accent is fire red, and a red button reads as an alarm about the
        // feed rather than as a control over it.
        .tint(.secondary)
    }
}
