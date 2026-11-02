import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The app's own icon, read from the app icon itself.
///
/// **One source, and this is the only view that reads it.** About and Welcome both show this view;
/// neither keeps an artwork copy of its own. The icon is the Icon Composer document the app already
/// ships as its app icon, and its name comes from the bundle rather than being typed here.
///
/// **How each platform reaches it.** macOS has `applicationIconImage`; iOS has no equivalent
/// public API, so it asks for the app icon by the name the bundle records in `CFBundleIconName`.
/// That is the same name Xcode used to build the icon, which is why it is read from the bundle
/// instead of written down twice.
struct AppIconView: View {

    let size: CGFloat

    var body: some View {
        if let icon {
            icon
                .resizable()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
                .accessibilityHidden(true)
        }
    }

    private var icon: Image? {
        #if os(iOS)
        guard let image = UIImage(named: AppIdentity.iconName) else { return nil }
        return Image(uiImage: image)
        #elseif os(macOS)
        let image = NSApplication.shared.applicationIconImage
            ?? NSImage(named: AppIdentity.iconName)
        guard let image else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }
}
