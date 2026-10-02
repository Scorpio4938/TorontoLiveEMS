import SwiftUI
import TorontoLiveEMSKit

/// The Info control, drawn once and used wherever it appears.
///
/// **Why this is its own type.** The two pages cannot host the same *capsule* — the incidents
/// page has a bar, and a bar draws its material itself; the map page has no bar, so the capsule
/// is drawn here. They can and now do host the same *controls*: the same symbol, the same
/// colour, the same name for VoiceOver. Everything that was drifting between the two pages was
/// in here, and none of it is decided anywhere else.
///
/// **No size of its own, deliberately.** A `.frame(width: 34, height: 34)` here — and a
/// `.font(.title3)` before it — made the platform's toolbar item wider than the platform's own,
/// and a wide trailing item pushes the bar's centred inline title off centre. That is why the
/// title ended up to the left, and it was reported from the two pages side by side before it was
/// traced. Both are gone. The symbol is the platform's size in the bar and its natural size in
/// the capsule, which is what lets the two hosts agree.
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
        }
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
        }
        .accessibilityLabel("Settings")
    }
}

/// The map's own control: which kind of map to draw.
///
/// **A `Menu` holding a `Picker`, not a list of buttons.** The picker gives the current kind the
/// platform's own checkmark, so the menu says which of the three is in force as well as offering
/// the other two — which a flat list of actions cannot do without this code drawing the mark
/// itself.
///
/// **The glyph is `map`, and that is a deliberate compromise.** A layers-style symbol reads better
/// for "map type", but there is no symbol list on the machine this was written on to check a name
/// against, and a symbol that does not exist draws *nothing at all* — an invisible control that
/// looks like a spacing bug. `map` is certain to exist. If it sits wrong beside the other two, the
/// name is the whole of the change.
struct MapKindControl: View {

    @Binding var mapKind: MapKind

    var body: some View {
        Menu {
            Picker("Map Type", selection: $mapKind) {
                ForEach(MapKind.allCases, id: \.self) { kind in
                    Text(kind.label).tag(kind)
                }
            }
        } label: {
            Image(systemName: "map")
                .foregroundStyle(Color.primary)
        }
        .accessibilityLabel("Map Type")
    }
}

/// The controls in the app's own capsule — drawn once, above every page.
///
/// **One layer, like the tab bar.** The tab bar is not part of either page: the container draws
/// it, and that is exactly why it cannot differ between them. This is the same arrangement at the
/// top of the screen, applied to the tab view by `screenControlsLayer`, so there is exactly one of
/// it — one declaration, one position, one rendering, over whichever page is showing and over a
/// pushed detail view as well. Nothing about it can drift between the pages, because there are not
/// two of them.
///
/// **Why it is not in the bars, which is where it started.** A bar draws its items itself: it pads
/// a custom item on top of whatever that view already carries, sizes a toolbar symbol by its own
/// rules, and moves its centred title when an item is wide. Every attempt to make two bars agree —
/// and then to make one bar agree with a hand-drawn capsule — was an attempt to reconcile two
/// renderers. One renderer cannot disagree with itself.
///
/// **The padding is what makes this capsule, not the icons.** With the controls left at their
/// natural size, the outer padding is the only thing giving this shape its size — which is the
/// point: it can be chunky here without making a toolbar item chunky there. The two paddings are
/// the knobs if the capsule reads too small or too large beside the bar's items, and the `16`
/// between the icons trades against them, since more space between the icons and a wider capsule
/// are the same points seen from two directions.
///
/// Order is ours, not asserted: the `HStack` puts Settings in the rightmost slot it has always
/// had, where the group it replaced relied on the platform laying items out in declaration order
/// and nothing here could check that it did.
///
/// **One exception, and it is on trial.** `mapKind` puts a *map* control in this capsule, which is
/// app-wide chrome. It is here to test the claim that adding a page's own control to one shared
/// layer is cheap and invisible to what is already there — the cost being that one capsule then
/// means two things: facts about the app, and a setting about a map.
struct ScreenControls: View {

    let onInfo: () -> Void
    let onSettings: () -> Void

    /// The map's own switch, present only where a map is on screen.
    ///
    /// **Leading rather than trailing, and that is the whole of the trick.** The capsule is
    /// trailing-aligned, so it grows to the left; putting the new control *first* leaves Info and
    /// Settings exactly where they were, and only the capsule's left edge moves. Appending it at
    /// the end would shift both of them by its width — which would be the one way this arrangement
    /// could disturb something that was already right.
    var mapKind: Binding<MapKind>? = nil

    var body: some View {
        HStack(spacing: 16) {
            if let mapKind {
                MapKindControl(mapKind: mapKind)
            }
            InfoControl(action: onInfo)
            SettingsControl(action: onSettings)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassSurface(cornerRadius: 22)
    }
}
