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

    @Test("calls ten or more vehicles a major response, and one more crew not")
    func marksAMajorResponse() {
        // The threshold is the City's own. Its meanings put the line between 1 and 2: 0 is an
        // initial response, 1 is a *support* fire response — one more crew — and 2 is already
        // 10–14 emergency vehicles.
        #expect(!AlarmLevel.isMajorResponse("0"))
        #expect(!AlarmLevel.isMajorResponse("1"))

        for level in ["2", "3", "4", "5", "6"] {
            #expect(AlarmLevel.isMajorResponse(level))
        }
    }

    @Test("does not mistake an unpublished or unreadable level for a major response")
    func missingLevelIsNotAMajorResponse() {
        #expect(!AlarmLevel.isMajorResponse(""))
        #expect(!AlarmLevel.isMajorResponse("   "))
        // The feed is inconsistent with itself, and a value we cannot read is one we must not
        // colour as though we could.
        #expect(!AlarmLevel.isMajorResponse("II"))
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
        #expect(AlarmLevel.escalationNote.contains("911 calls"))
        #expect(AlarmLevel.escalationNote.contains("smoke"))

        #expect(!AlarmLevel.countingNote.isEmpty)
        #expect(AlarmLevel.countingNote.contains("Pumpers"))
        #expect(AlarmLevel.countingNote.contains("are not counted"))
    }
}
