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

/// The bar at the bottom of both screens: the switcher, and refresh beside it.
///
/// **Shaped like the iOS 26 bottom bar, because that is what was asked for.** The reference is
/// Books, App Store and Find My: one floating bar of glass holding the sections, and a separate
/// circular button to its right. Checked against Apple's own interface rather than remembered —
/// `glassEffect(_:in:)`, `ButtonStyle.glass` and `ButtonStyle.glassProminent` all read out of the
/// SDK's SwiftUI interface, which is the material those apps are built from.
///
/// **A safe-area inset rather than a toolbar**, and that is still the point. Every bar this app
/// asked the platform to draw — a bottom-bar toolbar, the tab view's bottom accessory, a tab bar —
/// either failed to appear or appeared and refused to respond. This one is *content*: it insets the
/// screen rather than claiming a placement, so it renders for the same reason the list renders.
/// When a tab bar draws, this becomes a `TabView` and the design stops being imitated.
///
/// **Buttons, not a `Picker`.** It was a segmented control, and the Map segment could not be
/// selected — the control drew and did not take. A pair of buttons with the selection drawn into
/// them is the same thing the platform does and leaves nothing to bind.
struct ScreenSwitcherBar: View {

    @Binding var section: RootView.Section

    let model: IncidentFeedModel

    var body: some View {
        HStack(spacing: 10) {
            // The bar itself: one capsule of glass, holding the sections.
            HStack(spacing: 2) {
                ForEach(RootView.Section.allCases) { candidate in
                    sectionButton(for: candidate)
                }
            }
            .padding(4)
            // Glass where it exists. `glassEffect` is `@available(iOS 26.0, macOS 26.0, …)` and
            // explicitly **unavailable on visionOS** — and this target declares `xros` in
            // `SUPPORTED_PLATFORMS` with `TARGETED_DEVICE_FAMILY = "1,2,7"`, so that is a
            // destination Xcode will happily build for and fail on. Read out of the SDK interface;
            // the material is the fallback everywhere glass is not.
            #if os(iOS) || os(macOS)
            .glassEffect(.regular, in: Capsule())
            #else
            .background(.regularMaterial, in: Capsule())
            #endif

            Spacer(minLength: 0)

            // Beside it rather than inside it — a control belonging to the app, not to the
            // sections. This is the part of the reference layout that reads as a separate button.
            RefreshButton(model: model)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    /// The selected section is the prominent one. `buttonStyle` takes a concrete type, so this
    /// cannot be a ternary over two styles — it has to branch.
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
            .buttonStyle(.plain)
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
