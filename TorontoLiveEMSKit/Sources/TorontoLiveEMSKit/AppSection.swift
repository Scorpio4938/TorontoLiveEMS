import Foundation

/// One of the app's four sections.
///
/// **The tab bar's sections, and the launch rule's vocabulary.** Home is the index; Fire, Police
/// and Map are the pages with content of their own. The names are raw strings because the last one
/// the reader used is stored as a preference, and a preference is a string.
public enum AppSection: String, CaseIterable, Sendable {

    /// The app's index: counts, the two feeds' provenance, and the sources.
    ///
    /// **Never restored.** It is where a fresh install starts and where a reader can go, but a
    /// launch that reopened it would hide the page they were actually using.
    case home

    /// Active fire incidents.
    case fire

    /// Recent police calls.
    case police

    /// Both feeds on one map.
    case map

    /// Whether a launch may reopen this section.
    public var isRestorable: Bool {
        self != .home
    }
}

/// What a launch should open on.
///
/// **One stored fact decides it, and that fact is a version string's emptiness.** The key is the
/// version this device last acknowledged — the same key the welcome greeting reads and writes (#33).
/// Empty means this app has never been launched; anything else means it has.
///
/// **Home is not the launch screen, it is the first-launch screen.** A fresh install has no last
/// section to restore, so it opens the index. Every launch after opens the last of Fire, Police or
/// Map the reader used. Home is never restored even when it was the last section on screen: the
/// stored last section is only ever written for the pages with content, so Home cannot become one.
public enum LaunchBehaviour {

    /// The section a launch opens on.
    ///
    /// `lastUsed` is what the preference store holds, or `nil` when it holds nothing. A non-empty
    /// acknowledged version with no restorable last section falls back to Fire rather than Home,
    /// because Home is not a place to return to.
    public static func section(
        acknowledgedVersion: String,
        lastUsed: AppSection?
    ) -> AppSection {
        guard acknowledgedVersion.isEmpty else {
            if let lastUsed, lastUsed.isRestorable {
                return lastUsed
            }
            return .fire
        }
        return .home
    }
}
