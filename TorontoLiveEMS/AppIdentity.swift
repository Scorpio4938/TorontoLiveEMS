import Foundation

/// The app's identity, read from the bundle in one place.
///
/// **Read rather than typed.** A string in a screen is one that will one day disagree with the
/// bundle it was built from. *About* shows the name and the version, and the launch rule stores
/// the marketing version as the fact that this device has launched — so there is one reader of the
/// bundle, not two that can drift.
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
