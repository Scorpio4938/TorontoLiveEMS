import Foundation

/// Whether the app draws itself light, dark, or however the device is set.
///
/// **Three choices, not a switch.** A two-way toggle cannot express *follow the device*, and a reader
/// who once flipped it could never get back to it. System is therefore a value rather than the absence
/// of one, and it is the default, so nothing changes for anyone who never opens the setting.
///
/// **A stored preference like every other one here**, `RawRepresentable` over `String` because that is
/// what `@AppStorage` wants, and carrying its own label because the words a test pins should be the
/// words a reader sees.
///
/// **It deliberately knows nothing about SwiftUI**, and this package imports nothing from it. Saying
/// *nil means System* is the app's job, because `ColorScheme` is SwiftUI's and a value that names a
/// device setting is not the same kind of thing as a colour scheme. The mapping lives beside the
/// setting that applies it.
public enum Appearance: String, CaseIterable, Sendable {

    /// Whatever the device is set to: the default, and the app as it has always looked.
    case system

    /// Light, whatever the device is set to — which matters to a reader who keeps the phone dark all
    /// day and wants a map legible in sunlight.
    case light

    /// Dark, whatever the device is set to, for the reverse.
    case dark

    /// What a reader gets before they have chosen anything.
    ///
    /// Defined here rather than in each view so that changing it is a decision with a test on it. It
    /// only decides what an *unset* preference resolves to; a reader who has chosen either appearance
    /// keeps it, because `@AppStorage` writes their choice and this value is never consulted again.
    public static let standard: Appearance = .system

    /// The reader-facing name, for the setting that picks between them.
    public var label: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}
