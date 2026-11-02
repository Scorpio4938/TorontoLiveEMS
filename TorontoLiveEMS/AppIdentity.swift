import Foundation

/// The app's identity, read from the bundle in one place.
///
/// **Read rather than typed.** A string in a screen is one that will one day disagree with the
/// bundle it was built from. *About* takes the name and version from here, and the welcome takes the
/// same name; the welcome stores the marketing version as the fact that this device has launched —
/// so there is one reader of the bundle, not two that can drift.
///
/// The version is `MARKETING_VERSION` in the project, and the build is the number Xcode increments
/// for an upload. See `docs/releasing.md` for the scheme.
enum AppIdentity {

    /// The app's name, as the device shows it.
    ///
    /// No `CFBundleDisplayName` is set, so this is the target name — `TorontoLiveEMS`, without the
    /// spaces the app is called in prose. Setting `INFOPLIST_KEY_CFBundleDisplayName` to
    /// *Toronto Live EMS* is the whole of that change, and then both places say it without being
    /// told.
    static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "This app"
    }

    /// The checkpoint, `major.minor.checkpoint`.
    static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "unknown"
    }

    /// The name Xcode gives the app icon in the bundle.
    ///
    /// **Read rather than typed.** The Icon Composer document is called `TLEIcon.icon`, and Xcode
    /// records the primary icon's name in `CFBundleIconName`; reading it means the view that shows
    /// the icon and the build setting that names it cannot disagree. The literal is only a fallback
    /// for a bundle whose Info.plist carries neither entry.
    static var iconName: String {
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let name = primary["CFBundleIconName"] as? String
        {
            return name
        }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String
            ?? "TLEIcon"
    }

    /// The build number, which stays at 1 until the app is distributed.
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "unknown"
    }

    /// The checkpoint and the build, as a reader should see it.
    static var version: String {
        "\(marketingVersion) (\(build))"
    }
}
