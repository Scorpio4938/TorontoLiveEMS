import Testing
import TorontoLiveEMSKit

/// The rule that decides what a launch opens on.
///
/// The app target has no tests, so the rule lives in the package and is answered here. The stored
/// fact is the version string the welcome greeting will also read and write (#33): empty means this
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

    @Test("an acknowledged install restores the last page it used")
    func restoresTheLastPage() {
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .fire) == .fire)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .police) == .police)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .map) == .map)

        // Any non-empty version means the app has launched. An older one still restores, which is
        // what lets the welcome greeting later compare versions without changing this rule.
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.1", lastUsed: .map) == .map)
    }

    @Test("Home is never restored, and no stored page means Fire")
    func homeIsNeverRestored() {
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: .home) == .fire)
        #expect(LaunchBehaviour.section(acknowledgedVersion: "0.0.18", lastUsed: nil) == .fire)
    }

    @Test("only Home is not restorable")
    func restorableSections() {
        #expect(!AppSection.home.isRestorable)
        #expect(AppSection.fire.isRestorable)
        #expect(AppSection.police.isRestorable)
        #expect(AppSection.map.isRestorable)
    }
}
