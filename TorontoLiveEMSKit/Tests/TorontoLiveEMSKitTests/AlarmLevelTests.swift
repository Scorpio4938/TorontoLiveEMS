import Testing
import TorontoLiveEMSKit

@Suite("Alarm levels")
struct AlarmLevelTests {

    @Test("explains the level almost every incident carries")
    func explainsTheCommonLevel() {
        // 0 covers the overwhelming majority of incidents, so a bare "0" needs the
        // most help.
        #expect(AlarmLevel.meaning(for: "0") == "Initial response")
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
}
