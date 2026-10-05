import Foundation
import Testing

import TorontoLiveEMSKit

/// The call-type record the screens show, built from the calls themselves.
@Suite("Call types")
struct PoliceCallTypeTests {

    private static func call(_ objectID: Int, code: String, type: String) -> PoliceCall {
        PoliceCall(
            objectID: objectID,
            occurrenceTime: Date(timeIntervalSince1970: 1_791_219_259),
            division: "D14",
            latitude: 43.66,
            longitude: -79.42,
            callTypeCode: code,
            callType: type,
            crossStreets: "CHRISTIE ST - BLOOR ST W"
        )
    }

    @Test("pairs each code with the words the Service sent beside it")
    func pairsCodeWithName() {
        let types = PoliceCallType.published(in: [
            Self.call(1, code: "PERGU", type: "PERSON WITH A GUN"),
            Self.call(2, code: "ASSAULT", type: "ASSAULT"),
        ])

        #expect(types.count == 2)
        #expect(types[0].code == "ASSAULT")
        #expect(types[0].names == ["ASSAULT"])
        #expect(types[1].code == "PERGU")
        #expect(types[1].names == ["PERSON WITH A GUN"])
    }

    @Test("a code that many calls carried appears once")
    func aRepeatedCodeAppearsOnce() {
        // The reason this collects rather than lists: a busy afternoon of one call type must not
        // produce a legend with the same line twenty times.
        let types = PoliceCallType.published(in: [
            Self.call(1, code: "TRAFCO", type: "TRAFFIC COLLISION"),
            Self.call(2, code: "TRAFCO", type: "TRAFFIC COLLISION"),
            Self.call(3, code: "TRAFCO", type: "TRAFFIC COLLISION"),
        ])

        #expect(types.count == 1)
        #expect(types[0].code == "TRAFCO")
    }

    @Test("one code with two names keeps both, rather than choosing")
    func oneCodeTwoNamesKeepsBoth() {
        // If the Service varies its own wording while the app is watching, that is a fact about the
        // Service. Picking one would be this app deciding which of the Service's names is right.
        let types = PoliceCallType.published(in: [
            Self.call(1, code: "UNKTR", type: "UNKNOWN TROUBLE"),
            Self.call(2, code: "UNKTR", type: "UNKNOWN TROUBLE CALL"),
        ])

        #expect(types.count == 1)
        #expect(types[0].names == ["UNKNOWN TROUBLE", "UNKNOWN TROUBLE CALL"])
    }

    @Test("is ordered by code, and is the same every time")
    func orderIsStable() {
        // Sorted by code, so the list does not rearrange itself between reads — and `Set` is not
        // ordered, so the names inside an entry need sorting for the same reason.
        let calls = [
            Self.call(1, code: "ZZZ", type: "Z"),
            Self.call(2, code: "AAA", type: "A"),
            Self.call(3, code: "MMM", type: "M"),
        ]

        let first = PoliceCallType.published(in: calls)
        let second = PoliceCallType.published(in: calls.reversed())
        #expect(first.map(\.code) == ["AAA", "MMM", "ZZZ"])
        #expect(first == second, "the order the calls arrived in must not change the record")
    }

    @Test("no calls is no record, not an empty row")
    func noCallsIsNoRecord() {
        // A quiet four hours, and the first fetch before anything has arrived. The screen shows its
        // own sentence in that case; it must not have to filter a placeholder out.
        #expect(PoliceCallType.published(in: []).isEmpty)
    }
}
