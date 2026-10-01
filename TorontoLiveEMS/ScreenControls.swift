import SwiftUI

/// The two controls every page carries, in the one shape this app draws them in.
///
/// **One definition, two hosts.** The incidents page has a navigation bar, so this is the
/// content of a toolbar item there — with the platform's shared glass hidden, because the glass
/// in this app is drawn here. The map page has no bar, so the same view floats over the map.
///
/// Before this there were two implementations of the same two buttons: a toolbar item the
/// platform drew, and a capsule drawn by hand. They could be brought close by numbers and never
/// made equal, because the bar owns its material, its padding, its item spacing and its
/// placement outright, and may clamp a toolbar icon's size. Two renderers cannot be matched.
/// One renderer can.
///
/// Order is ours, not asserted: the `HStack` puts Settings in the rightmost slot it has always
/// had. The group it replaced relied on the platform laying items out in declaration order,
/// which nothing here could check.
///
/// **Label colour, not the tint.** A plain button's icon takes the app's accent — fire red —
/// and two red icons over a map read as alarms. The platform draws toolbar icons in the label
/// colour, so that is asked for here, on the icons: a style on the content is what overrides a
/// button's tint, not one on the container.
///
/// **Icons only, with their names kept.** A capsule is a button's shape, not a label's; the
/// accessibility labels are what carry "About this Data" and "Settings" to VoiceOver.
///
/// **16 between the icons.** Reported from the two pages side by side when the bar's items read
/// further apart than the floating capsule's did. The capsule's outer padding is the
/// neighbouring knob, and it trades against the total width: more space between the icons and a
/// wider capsule are the same points seen from two directions.
struct ScreenControls: View {

    let onInfo: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.primary)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("About this Data")

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .foregroundStyle(Color.primary)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("Settings")
        }
        .font(.title3)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassSurface(cornerRadius: 21)
    }
}
