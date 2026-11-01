import Testing
import TorontoLiveEMSKit

/// The rule that decides what a launch opens on.
///
/// The app target has no tests, so the rule lives in the package and is answered here. The stored
/// fact is the version string the welcome greeting also reads and writes (#33): empty means this
/// app has never been launched.
@Suite("Launch section")
struct AppSectionTests {

    @Test("nothing acknowledged opens Home, whatever was last used")
    func freshInstallOpensHome() {
        #expect(LaunchBehaviour.section(acknowledgedVersion: "", lastUsed: nil) == .home)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "", lastUsed: .fire) == .home)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "", lastUsed: .police) == .home)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "", lastUsed: .map) == .home)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "", lastUsed: .home) == .home)
    }

    @Test("an acknowledged install restores the last page it used, Home included")
    func restoresTheLastPage() {
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .home) == .home)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .fire) == .fire)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .police) == .police)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .map) == .map)

        // Any non-empty version means the app has launched. An older one still restores, which is
        // what lets the welcome greeting compare versions without changing this rule.
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.1", lastUsed: .map) == .map)
    }

    @Test("no stored page falls back to Fire, not Home")
    func noStoredPageFallsBackToFire() {
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: nil) == .fire)
    }
}
