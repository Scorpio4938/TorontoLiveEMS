/// One of the app's four sections.
///
/// **The tab bar's sections, and the launch rule's vocabulary.** Home is the index; Fire, Police
/// and Map are the pages with content of their own. The names are raw strings because the last one
/// the reader used is stored as a preference, and a preference is a string.
public enum AppSection: String, CaseIterable, Sendable {

    /// The app's index: counts, the two feeds' provenance, and the sources.
    ///
    /// **The first-launch screen, and restorable like any other.** A fresh install opens here
    /// because it has no last section; after that, a launch reopens whatever the reader was last
    /// looking at, including this index.
    case home

    /// Active fire incidents.
    case fire

    /// Recent police calls.
    case police

    /// Both feeds on one map.
    case map
}

/// What a launch should open on.
///
/// **One stored fact decides it, and that fact is a version string's emptiness.** The key is the
/// version this device last acknowledged — the same key the welcome greeting reads and writes (#33).
/// Empty means this app has never been launched; anything else means it has.
///
/// **Home is the first-launch screen, not a default.** A fresh install has no last section to
/// restore, so it opens the index. Every launch after opens the last of Home, Fire, Police or Map
/// the reader used. Restoring Home is not the same as defaulting to it: an acknowledged install
/// with no stored section still falls back to Fire, so Home cannot become the launch screen merely
/// because nothing was remembered.
public enum LaunchBehaviour {

    /// The section a launch opens on.
    ///
    /// `lastUsed` is what the preference store holds, or `nil` when it holds nothing. A non-empty
    /// acknowledged version with no stored section falls back to Fire rather than Home, so Home is
    /// still never the default; it is only restored when it is the fact that was stored.
    public static func section(
        acknowledgedVersion: String,
        lastUsed: AppSection?
    ) -> AppSection {
        guard acknowledgedVersion.isEmpty else {
            return lastUsed ?? .fire
        }
        return .home
    }
}
