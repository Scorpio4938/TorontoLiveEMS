import SwiftUI

/// The chrome a catalogue wears while its map is showing.
///
/// **The live map's arrangement, applied here.** A map under a navigation bar gets the bar's own
/// glass as a tinted band, and no scroll-edge setting removes it — those configure scroll views, and
/// a map has none. The live map's answer is to hide the bar and float its name and controls over the
/// map, so the catalogue does the same: nothing above the map but the map.
///
/// **The menu is the one control that has to travel — and it travels as a title.** In list mode it is
/// the bar's principal item, where its label reads as the catalogue's title. In map mode it floats at
/// the top centre in the same idiom the live map uses for its floating title: plain text in the
/// primary label colour, with no capsule behind it. A capsule was tried and is wrong here: it puts a
/// box around the page's name and, outside a toolbar, the menu's label takes the app's accent, so the
/// header read as a red button. The mode glyph and chevron say it opens; the colour says it is a name.
///
/// **The back control is the guarantee, not a decoration.** Hiding a navigation bar can take the
/// interactive swipe-back with it, and a pushed catalogue must not become a map with no way home.
/// The swipe may still work; this control is what makes the acceptance criterion true without
/// depending on that. It shares the capsule's height and radius with everything else here.
///
/// **One rule for both catalogues.** `catalogueChrome` below is where the bar-versus-floating decision
/// lives, so Stations and Divisions cannot come to wear their maps differently.
struct CatalogueMapChrome: View {

    let title: String

    @Binding var mode: CatalogueMode

    let onBack: () -> Void

    var body: some View {
        ZStack {
            // Plain, with its own padded tap target: see `CatalogueModeMenu.floats`.
            CatalogueModeMenu(title: title, mode: $mode, floats: true)

            HStack {
                CatalogueBackControl(action: onBack)
                Spacer()
            }
        }
        // The same band the shared controls are centred in, so the three floating pieces sit on one
        // line rather than each finding its own height.
        .frame(height: ScreenControls.bandHeight, alignment: .center)
        .padding(.horizontal, 12)
    }
}

/// The way back while the bar is hidden.
///
/// A capsule of its own rather than a bare chevron: it is a control over a map, and the app's other
/// controls over a map are capsules. Its width is the smallest that gives the chevron a comfortable
/// target without reading as a circle.
private struct CatalogueBackControl: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.body)
                .foregroundStyle(Color.primary)
                .frame(width: 44)
                .padding(.vertical, ScreenControls.verticalPadding)
        }
        // Plain: the glass capsule is the surface, so no second platform-drawn background appears
        // behind it.
        .buttonStyle(.plain)
        .glassSurface(cornerRadius: ScreenControls.cornerRadius)
        .accessibilityLabel("Back")
    }
}

extension View {

    /// A catalogue's chrome: its bar in list mode, its floating controls in map mode.
    ///
    /// **The map keeps the bar's furniture and loses the bar.** The title, the List/Map menu and the
    /// way back are the bar's contents; hiding the bar is what removes the tinted band, so those
    /// contents float instead of disappearing. The list branch is left exactly as it was, edge and
    /// all — only its mode matters here, not its layout.
    func catalogueChrome(
        title: String,
        mode: Binding<CatalogueMode>,
        onBack: @escaping () -> Void
    ) -> some View {
        self
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    CatalogueModeMenu(title: title, mode: mode)
                }
            }
            .catalogueMapBar(title: title, mode: mode, onBack: onBack)
    }
}

private extension View {

    /// Hides the bar over a catalogue's map and floats its furniture instead.
    ///
    /// iOS only. Elsewhere the controls live in the window toolbar: hiding the bar there would take
    /// the app's own controls away rather than a tinted band, and no capsule floats over the map to
    /// replace them. The live map keeps its `barControls` for the same reason.
    @ViewBuilder
    func catalogueMapBar(
        title: String,
        mode: Binding<CatalogueMode>,
        onBack: @escaping () -> Void
    ) -> some View {
        #if os(iOS)
        // A map has no scroll view for the soft edge to treat, and the bar's own glass is the band.
        // Hiding it is the only thing that removes the band, which the live map found.
        let isMap = mode.wrappedValue == .map
        self
            .toolbar(isMap ? .hidden : .visible, for: .navigationBar)
            .overlay(alignment: .top) {
                if isMap {
                    CatalogueMapChrome(title: title, mode: mode, onBack: onBack)
                }
            }
        #else
        self
        #endif
    }
}
