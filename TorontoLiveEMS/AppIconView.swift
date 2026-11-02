import SwiftUI

/// The app's icon, drawn once for every screen that shows it.
///
/// **One display mark, not a copy per screen.** About and Welcome both use this view. The mark is
/// the layer the Icon Composer document was built from, placed in the asset catalogue once; the
/// ground and the glyph colour are the same two appearances Icon Composer declares for it.
///
/// **Why not read the app icon itself.** On iOS an Icon Composer app icon resolves to a special
/// rendition rather than a general-purpose image: asking `UIImage(named:)` for it raises
/// *"Need an imageRef"* before returning. The compiled icon is not readable that way, so the one
/// artwork file is drawn here instead of asking the system for the icon it was compiled into. The
/// app icon remains the Icon Composer document; this is the same artwork, once.
struct AppIconView: View {

    let size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    /// The icon's ground: the **solid red** the appearance declares, and the navy it uses for dark.
    ///
    /// Both are the document's own values rather than approximations of it, and it is a flat fill
    /// here because it is one in the document — the earlier automatic gradient is gone, so a
    /// gradient drawn here would be a second, different icon.
    private var ground: Color {
        colorScheme == .dark
            ? Color(.sRGB, red: 0.03607, green: 0.10680, blue: 0.22221, opacity: 1)
            : Color(.sRGB, red: 0.48901, green: 0.09399, blue: 0.13403, opacity: 1)
    }

    /// The light mark is the near-white the icon declares; dark is its red, which reads against navy.
    private var mark: Color {
        colorScheme == .dark
            ? Color(.sRGB, red: 0.49622, green: 0.09080, blue: 0.12942, opacity: 1)
            : Color(.sRGB, red: 0.95000, green: 0.95000, blue: 0.95000, opacity: 1)
    }

    var body: some View {
        ZStack {
            ground

            Image("AppIconMark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(mark)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
        .accessibilityHidden(true)
    }
}
