import Testing
import TorontoLiveEMSKit

@Suite("Alarm levels")
struct AlarmLevelTests {

    @Test("explains the level almost every incident carries")
    func explainsTheCommonLevel() {
        // 0 covers the overwhelming majority of incidents, so a bare "0" needs the
        // most help.
        // The City's words, including the part that says *any* event — level 0 is not the
        // fire-specific case, and dropping "(for any event)" loses that.
        #expect(AlarmLevel.meaning(for: "0") == "Initial response (for any event)")
    }

    @Test("explains every level the City documents")
    func explainsEveryDocumentedLevel() {
        for level in ["0", "1", "2", "3", "4", "5", "6"] {
            #expect(AlarmLevel.meaning(for: level) != nil)
        }
    }

    @Test("says nothing about a level the City has not documented")
    func unknownLevel() {
        #expect(AlarmLevel.meaning(for: "9") == nil)
        #expect(AlarmLevel.meaning(for: "") == nil)
        #expect(AlarmLevel.meaning(for: "major") == nil)
    }

    @Test("marks every level above the initial response")
    func marksEscalation() {
        // 0 is an initial response and covers 99.76% of incidents, so it is the neutral
        // case and must not be marked.
        #expect(!AlarmLevel.isEscalated("0"))

        for level in ["1", "2", "3", "4", "5", "6"] {
            #expect(AlarmLevel.isEscalated(level))
        }
    }

    @Test("does not mistake an unpublished level for an escalation")
    func missingLevelIsNotEscalation() {
        #expect(!AlarmLevel.isEscalated(""))
        #expect(!AlarmLevel.isEscalated("   "))
    }

    @Test("lists the levels in the order they are meant to be read")
    func levelsAreOrdered() {
        // A dictionary of the same values has no order, which is why the list exists. This is
        // what a screen renders, so a level appearing out of sequence is visible.
        #expect(AlarmLevel.levels.map(\.published) == ["0", "1", "2", "3", "4", "5", "6"])
    }

    @Test("gives every listed level a meaning, and every meaning a level")
    func theListAndTheLookupAgree() {
        // `meaning(for:)` reads from a dictionary derived from this list, so the two cannot
        // disagree — but only for as long as the list is what they are both built on.
        for level in AlarmLevel.levels {
            #expect(!level.meaning.isEmpty)
            #expect(AlarmLevel.meaning(for: level.published) == level.meaning)
        }
        #expect(AlarmLevel.levels.count == AlarmLevel.levels.map(\.published).count)
    }

    @Test("carries the City's two explanations of Alarm Level")
    func carriesTheCitysOwnExplanations() {
        // Both are quoted from the City's page rather than written here, so the test is that
        // they exist and say what they are for. The counting note is the one that stops a
        // reader concluding the app has miscounted their incident's vehicles.
        #expect(!AlarmLevel.escalationNote.isEmpty)
        #expect(AlarmLevel.escalationNote.contains("Toronto Fire Services determines the Alarm Level"))

        #expect(!AlarmLevel.countingNote.isEmpty)
        #expect(AlarmLevel.countingNote.contains("Pumpers"))
        #expect(AlarmLevel.countingNote.contains("not included"))
    }
}
