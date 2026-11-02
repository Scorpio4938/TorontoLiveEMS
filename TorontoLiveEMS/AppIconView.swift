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

    /// The icon's ground: the teal SVG Repo artwork sits on in the default appearance, and the navy
    /// Icon Composer uses for dark. A slight gradient keeps it from reading as a flat swatch.
    private var ground: LinearGradient {
        if colorScheme == .dark {
            let navy = Color(.sRGB, red: 0.036, green: 0.107, blue: 0.222, opacity: 1)
            return LinearGradient(colors: [navy, navy], startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(
            colors: [
                Color(.sRGB, red: 0.36, green: 0.72, blue: 0.68, opacity: 1),
                Color(.sRGB, red: 0.28, green: 0.64, blue: 0.60, opacity: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The light mark is white; dark uses the teal the icon declares for its own dark appearance.
    private var mark: Color {
        colorScheme == .dark
            ? Color(.sRGB, red: 0.315, green: 0.687, blue: 0.643, opacity: 1)
            : .white
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
