import SwiftUI
import TorontoLiveEMSKit

/// The one place a stored appearance becomes the colour scheme SwiftUI understands.
///
/// **`nil` is System, and it is the value that means "ask the window".** The package's type names a
/// device setting and holds no SwiftUI; `ColorScheme` is SwiftUI's, so the mapping lives here. It is
/// written once rather than at each screen, because an appearance is the app's and not a page's.
extension Appearance {

    /// The scheme to ask the window for, or `nil` to leave the window's own choice alone.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
