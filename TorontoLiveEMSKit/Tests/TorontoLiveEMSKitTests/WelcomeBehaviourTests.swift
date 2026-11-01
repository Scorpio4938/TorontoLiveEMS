import Testing

import TorontoLiveEMSKit

/// The rule that decides whether a launch needs to say anything.
///
/// The stored fact is the version this device last acknowledged. Empty is a welcome; a declared
/// version newer than the stored one is a notice; everything else is silence. The app target has no
/// tests, so the rule lives here.
@Suite("Welcome behaviour")
struct WelcomeBehaviourTests {

    @Test("nothing stored welcomes, whatever is declared")
    func firstLaunchWelcomes() {
        #expect(WelcomeBehaviour.decision(storedVersion: "", declaredVersion: nil) == .welcome)
        #expect(
            WelcomeBehaviour.decision(storedVersion: "", declaredVersion: "0.0.20") == .welcome
        )
    }

    @Test("stored with nothing declared says nothing")
    func acknowledgedWithNoDeclarationIsSilent() {
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.20", declaredVersion: nil) == .nothing
        )
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.20", declaredVersion: "") == .nothing
        )
    }

    @Test("stored equal to the declared version says nothing")
    func sameVersionIsSilent() {
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.20", declaredVersion: "0.0.20")
                == .nothing
        )
    }

    @Test("stored older than a declared version is a notice")
    func olderVersionIsNoticed() {
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.19", declaredVersion: "0.0.20")
                == .notice(version: "0.0.20")
        )
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.9", declaredVersion: "0.0.10")
                == .notice(version: "0.0.10")
        )
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.9.9", declaredVersion: "1.0.0")
                == .notice(version: "1.0.0")
        )
    }

    @Test("stored newer than the declared version stays quiet")
    func newerVersionIsSilent() {
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.21", declaredVersion: "0.0.20")
                == .nothing
        )
    }

    @Test("an unreadable version is not treated as older")
    func unreadableVersionsStayQuiet() {
        #expect(
            WelcomeBehaviour.decision(storedVersion: "unknown", declaredVersion: "0.0.20")
                == .nothing
        )
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0.20", declaredVersion: "next")
                == .nothing
        )
        #expect(
            WelcomeBehaviour.decision(storedVersion: "0.0", declaredVersion: "0.0.20")
                == .nothing
        )
    }
}
