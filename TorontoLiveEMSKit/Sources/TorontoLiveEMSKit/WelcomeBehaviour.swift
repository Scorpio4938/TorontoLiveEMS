/// What the app should say about what this device has already seen.
///
/// **A version comparison, not a boolean.** The stored value is the version this device last
/// acknowledged. Empty means it has never been greeted. Anything else is a version the reader has
/// seen, which is exactly what a later notice needs to compare against a declared release without
/// adding another preference.
public enum WelcomeDecision: Equatable, Sendable {

    /// This device has never been greeted. Show the welcome.
    case welcome

    /// A newer declared version exists and the device has seen an earlier one. Show a notice.
    case notice(version: String)

    /// There is nothing to say: either the greeting has already happened and nothing is declared,
    /// or the declared version is not newer than what the reader has seen.
    case nothing
}

/// The rule that decides whether a launch should welcome, notice, or stay quiet.
///
/// **The declaration is a constant copied from the changelog.** There is no in-app release list to
/// read, so a declaration is somebody's deliberate copy of the newest release when they decide to
/// announce it. Today nothing is declared; the rule is written and tested now so adding one later
/// is a call-site change rather than a redesign.
public enum WelcomeBehaviour {

    public static func decision(
        storedVersion: String,
        declaredVersion: String?
    ) -> WelcomeDecision {
        // Nothing stored is the one unambiguous welcome. A declaration cannot override this: a
        // first launch is greeted before any notice can apply.
        guard !storedVersion.isEmpty else { return .welcome }

        guard let declaredVersion, !declaredVersion.isEmpty else { return .nothing }

        // An unreadable version is not evidence that the reader is behind. Staying quiet is the
        // honest answer when the comparison cannot be made.
        guard isOlder(storedVersion, than: declaredVersion) else { return .nothing }
        return .notice(version: declaredVersion)
    }

    /// Whether `stored` is an earlier `major.minor.checkpoint` than `declared`.
    private static func isOlder(_ stored: String, than declared: String) -> Bool {
        guard
            let storedParts = components(stored),
            let declaredParts = components(declared)
        else {
            return false
        }
        return storedParts.lexicographicallyPrecedes(declaredParts)
    }

    private static func components(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        let numbers = parts.compactMap { Int($0) }
        return numbers.count == 3 ? numbers : nil
    }
}
