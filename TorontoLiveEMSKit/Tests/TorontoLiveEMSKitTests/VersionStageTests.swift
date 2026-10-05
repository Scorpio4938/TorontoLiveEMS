import Testing

import TorontoLiveEMSKit

/// The stage rule, which is the whole of what a version number says about how finished the app is.
@Suite("Version stage")
struct VersionStageTests {

    @Test("before 1.0 is alpha, and 1.0 onwards is not")
    func readsTheLeadingZero() {
        #expect(VersionStage.of("0.0.9") == .alpha)
        #expect(VersionStage.of("0.1.0") == .alpha)
        #expect(VersionStage.of("1.0.0") == .released)
        #expect(VersionStage.of("2.3.4") == .released)
    }

    @Test("a version with one component is still read")
    func readsShortVersions() {
        // Not a version this project produces — the scheme is three numbers — but reading it is
        // free, and refusing it would mean a screen that says nothing about an app called "0".
        #expect(VersionStage.of("0") == .alpha)
        #expect(VersionStage.of("1") == .released)
    }

    @Test("anything that is not a version has no stage")
    func refusesWhatItCannotRead() {
        // Nil rather than a guess: a screen that says nothing beats one that says the wrong thing.
        #expect(VersionStage.of("") == nil)
        #expect(VersionStage.of("unknown") == nil)
        #expect(VersionStage.of("0.0.1a1") == nil, "the letters are exactly what this replaced")
        #expect(VersionStage.of(".9") == nil)
    }

    @Test("every stage has a name and an explanation of its own")
    func labelsAndNotesAreDistinct() {
        let labels = VersionStage.allCases.map(\.label)
        let notes = VersionStage.allCases.map(\.note)
        #expect(labels.allSatisfy { !$0.isEmpty })
        #expect(notes.allSatisfy { !$0.isEmpty })
        #expect(Set(labels).count == labels.count)
        #expect(Set(notes).count == notes.count)
    }
}
