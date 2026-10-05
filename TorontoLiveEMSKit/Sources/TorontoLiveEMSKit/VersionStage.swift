import Foundation

/// How finished a version number says the app is.
///
/// The scheme is in `docs/releasing.md`: `major.minor.checkpoint`. **The leading zero is the only
/// place "alpha" is written down**, and that is deliberate on two counts — `CFBundleShortVersionString`
/// must be period-separated integers, so a version cannot carry the word at all, and the number
/// states it better than the word would: `0.0.9` promises nothing, and `1.0.0` does.
///
/// Derived here rather than in the screen that shows it, because the app target has no tests and
/// this is a rule about the scheme rather than a label somebody chose. The screen's own comment
/// says the same thing about the other strings it shows: the words a test pins are the words a
/// reader sees.
public enum VersionStage: String, Sendable, CaseIterable {

    /// Before 1.0: usable, unfinished, and promised to nobody.
    case alpha

    /// At or after 1.0: something a person is meant to have.
    case released

    /// The stage a version number reports, or `nil` when it is not a version number at all.
    ///
    /// `nil` rather than a guess. A value this cannot read — a build with no version, a string
    /// somebody typed — has no stage, and a screen that says nothing about the stage is better than
    /// one that says the wrong thing about it.
    public static func of(_ version: String) -> VersionStage? {
        let leading = version.split(separator: ".").first
        guard let leading, let major = Int(leading) else { return nil }
        return major == 0 ? .alpha : .released
    }

    /// The sentence a screen shows beside the version, when it has one to show.
    ///
    /// Written for a reader who has just found the version number and is wondering what it says
    /// about the app in their hand, which is the question the number is there to answer. The word
    /// *alpha* is in here rather than in a `label` of its own, because this is the only sentence
    /// that shows it and a second name for the same thing is a second thing to keep true.
    public var note: String {
        switch self {
        case .alpha:
            return """
                Alpha: usable, unfinished, and promised to nobody — the leading 0 is what says so.
                """
        case .released:
            return "A version meant to be used."
        }
    }
}
