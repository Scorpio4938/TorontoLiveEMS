import Testing

import TorontoLiveEMSKit

/// The static code-to-name list the screens show.
@Suite("Call types")
struct PoliceCallTypeTests {

    @Test("every code appears once")
    func codesAreUnique() {
        let codes = PoliceCallType.documented.map(\.code)
        #expect(Set(codes).count == codes.count)
    }

    @Test("the list is ordered by code")
    func orderIsByCode() {
        let codes = PoliceCallType.documented.map(\.code)
        #expect(codes == codes.sorted())
    }

    @Test("the count is pinned, so changing the list is deliberate")
    func countIsPinned() {
        // The list is static and was gathered from two windows of the Service's four hours — ninety-six
        // calls that yielded thirty codes, and a later one that yielded twelve more. A change to it
        // should be a decision somebody made rather than something that drifted in, which is what this
        // assertion is for. The count is not a target: it is a record of what has been seen, and it will
        // be wrong the moment the Service uses something new.
        #expect(PoliceCallType.documented.count == 45)
    }

    @Test("no entry is blank")
    func nothingIsBlank() {
        for type in PoliceCallType.documented {
            #expect(!type.code.isEmpty)
            #expect(!type.name.isEmpty)
        }
    }

    @Test("pairs codes with the words the Service sends beside them")
    func spotChecks() {
        let byCode = Dictionary(
            uniqueKeysWithValues: PoliceCallType.documented.map { ($0.code, $0.name) }
        )
        #expect(byCode["DIS"] == "DISORDERLIES")
        #expect(byCode["PERGU"] == "PERSON WITH A GUN")
        #expect(byCode["UNKTR"] == "UNKNOWN TROUBLE")
        // The two that arrived second, and the reason there was a second gathering at all: a robbery and
        // a person with a knife were both drawn as question marks because their codes were unknown.
        #expect(byCode["ROB"] == "ROBBERY")
        #expect(byCode["PERKN"] == "PERSON WITH A KNIFE")
        // A third report from the map, and the same shape: a code the app had never met, drawn as a
        // question mark. This one is a stabbing.
        #expect(byCode["STA"] == "STABBING")
    }

    @Test("the codes cannot be read as abbreviations, which is why they are listed")
    func codesAreNotCompositional() {
        // Both of these mean indecent exposure, and only one says so in its spelling. Any code in
        // this app that tried to decode a code rather than look it up would get one of them wrong.
        let byCode = Dictionary(
            uniqueKeysWithValues: PoliceCallType.documented.map { ($0.code, $0.name) }
        )
        #expect(byCode["INDEX"] == "INDECENT EXPOSURE")
        #expect(byCode["EXPJU"] == "INDECENT EXPOSURE JUST OCCURRED")
    }

    @Test("the names a reader sees in Settings are the ones a test pins")
    func labelsArePinned() {
        #expect(PoliceCallTypeStyle.words.label == "Words")
        #expect(PoliceCallTypeStyle.code.label == "Code")
        #expect(
            PoliceCallTypeStyle.allCases.count == 2,
            "a third option would need somewhere in the column to go"
        )
    }
}
