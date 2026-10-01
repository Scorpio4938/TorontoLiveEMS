import SwiftUI

/// The Info control, drawn once and used wherever it appears.
///
/// **Why this is its own type.** The two pages cannot host the same *capsule* — the incidents
/// page has a bar, and a bar draws its material itself; the map page has no bar, so the capsule
/// is drawn here. They can and now do host the same *controls*: the same symbol, the same size,
/// the same colour, the same name for VoiceOver. Everything that was drifting between the two
/// pages was in here, and none of it is decided anywhere else.
///
/// **Label colour, not the tint.** A plain button's icon takes the app's accent — fire red —
/// and two red icons over a map read as alarms. The platform draws toolbar icons in the label
/// colour, so that is asked for here, on the icon: a style on the content is what overrides a
/// button's tint, not one on the container.
struct InfoControl: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.primary)
                .frame(width: 34, height: 34)
        }
        .font(.title3)
        .accessibilityLabel("About this Data")
    }
}

/// The Settings control, drawn once and used wherever it appears. See `InfoControl`.
struct SettingsControl: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape")
                .foregroundStyle(Color.primary)
                .frame(width: 34, height: 34)
        }
        .font(.title3)
        .accessibilityLabel("Settings")
    }
}

/// The two controls in the app's own capsule: the shape for a page that has no bar to hold
/// them, and the one the bars' items are drawn to match.
///
/// **What is shared, and what cannot be.** The controls above are shared with `AppToolbar`
/// exactly. The capsule is not, and it was tried: hosting this whole view as a toolbar item —
/// even with `sharedBackgroundVisibility(.hidden)`, which exists and does suppress the
/// platform's glass — made the two pages *less* alike, not more. The items came out larger,
/// because the platform pads a custom item on top of what the view already carries, and the
/// centred inline title moved off centre. Which of the two is the cause is not established;
/// that the bar and a hand-drawn capsule cannot be made to agree is.
///
/// So the bar keeps its own material around the same two controls, and this capsule is the
/// map's. What is left differing is who draws the capsule, which is not a number either page
/// can set.
///
/// Order is ours, not asserted: the `HStack` puts Settings in the rightmost slot it has always
/// had, where the group it replaced relied on the platform laying items out in declaration
/// order and nothing here could check that it did.
///
/// **16 between the icons.** Reported from the two pages side by side when the bar's items read
/// further apart than the floating capsule's did. The outer padding is the neighbouring knob and
/// trades against the total width: more space between the icons and a wider capsule are the same
/// points seen from two directions.
struct ScreenControls: View {

    let onInfo: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            InfoControl(action: onInfo)
            SettingsControl(action: onSettings)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassSurface(cornerRadius: 21)
    }
}
