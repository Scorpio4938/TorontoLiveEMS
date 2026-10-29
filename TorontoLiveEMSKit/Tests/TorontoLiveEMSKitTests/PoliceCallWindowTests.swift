import Foundation
import Testing

import TorontoLiveEMSKit

/// How far back a police screen looks, and what it folds away.
@Suite("Police call window")
struct PoliceCallWindowTests {

    /// 12:00:00 UTC, so that an hour either side of it is easy to read in a failure.
    private static let now = Date(timeIntervalSince1970: 1_791_220_800)

    private static func call(
        _ objectID: Int,
        minutesAgo: Double,
        code: String = "DIS"
    ) -> PoliceCall {
        PoliceCall(
            objectID: objectID,
            occurrenceTime: now.addingTimeInterval(-minutesAgo * 60),
            division: "D14",
            latitude: 43.66,
            longitude: -79.42,
            callTypeCode: code,
            callType: "AS THE SERVICE SENT IT",
            crossStreets: nil
        )
    }

    private static func split(
        _ calls: [PoliceCall],
        window: PoliceCallWindow = .oneHour,
        keepingCritical: Bool = true
    ) -> (shown: [PoliceCall], folded: [PoliceCall]) {
        window.split(calls, keepingCritical: keepingCritical, now: now)
    }

    // MARK: - The window itself

    @Test("the windows are the lengths they say they are")
    func windowsAreTheirStatedLengths() {
        #expect(PoliceCallWindow.thirtyMinutes.duration == 30 * 60)
        #expect(PoliceCallWindow.oneHour.duration == 60 * 60)
        #expect(PoliceCallWindow.twoHours.duration == 2 * 60 * 60)
        // Four hours is the Service's own window, so a fifth setting would be indistinguishable from
        // this one rather than merely unwelcome.
        #expect(
            PoliceCallWindow.allCases.count == 4,
            "beyond four hours the Service publishes nothing, so a fifth would equal the fourth"
        )
        #expect(PoliceCallWindow.fourHours.duration == 4 * 60 * 60)
    }

    @Test("every window has a name")
    func everyWindowIsNamed() {
        for window in PoliceCallWindow.allCases {
            #expect(!window.label.isEmpty, "\(window) has no name")
        }
    }

    // MARK: - The split

    @Test("a call inside the window is shown and one outside it is folded")
    func recentIsShownAndOldIsFolded() {
        // 12:00, with a call ten minutes old and one ninety minutes old. An hour is the line.
        let result = Self.split([Self.call(1, minutesAgo: 10), Self.call(2, minutesAgo: 90)])

        #expect(result.shown.map(\.objectID) == [1])
        #expect(result.folded.map(\.objectID) == [2])
    }

    @Test("the window's edge is inside it")
    func theEdgeBelongsToTheWindow() {
        // Exactly an hour old is *in* the last hour. A boundary that excluded it would drop a call that
        // has just arrived as the reader opened the page, which is the one call they most want.
        let result = Self.split([Self.call(1, minutesAgo: 60)])
        #expect(result.shown.map(\.objectID) == [1])
    }

    @Test("a critical call from outside the window is shown anyway")
    func criticalCallsAreKeptByDefault() {
        // The exemption: a shooting three hours ago is worth a reader's attention now, where a theft
        // three hours ago is not.
        let result = Self.split([Self.call(1, minutesAgo: 180, code: "SHO")])
        #expect(result.shown.map(\.objectID) == [1])
        #expect(result.folded.isEmpty)
    }

    @Test("and folded when the reader has turned the exemption off")
    func criticalCallsFoldWhenAsked() {
        let result = Self.split([Self.call(1, minutesAgo: 180, code: "SHO")], keepingCritical: false)
        #expect(result.shown.isEmpty)
        #expect(result.folded.map(\.objectID) == [1])
    }

    @Test("an ordinary call from outside the window folds even with the exemption on")
    func onlyCriticalCallsAreExempt() {
        // The line the exemption has to hold: it is about severity, not about age or about kind.
        let result = Self.split([Self.call(1, minutesAgo: 180, code: "THE")])
        #expect(result.shown.isEmpty)
        #expect(result.folded.map(\.objectID) == [1])
    }

    @Test("a call the app cannot name folds rather than shouting")
    func unknownCallsFold() {
        // An unseen code is `.unknown`, which is not `.critical`. A code nobody has told this app about
        // must not be the thing that keeps a four-hour-old call on screen.
        let result = Self.split([Self.call(1, minutesAgo: 180, code: "BRANDNEW")])
        #expect(result.folded.map(\.objectID) == [1])
    }

    @Test("each window folds a different amount of the same list")
    func theWindowChangesWhatIsFolded() {
        // Three calls, 10, 45 and 90 minutes old, against all three windows.
        let calls = [Self.call(1, minutesAgo: 10), Self.call(2, minutesAgo: 45), Self.call(3, minutesAgo: 90)]

        #expect(Self.split(calls, window: .thirtyMinutes).shown.map(\.objectID) == [1])
        #expect(Self.split(calls, window: .oneHour).shown.map(\.objectID) == [1, 2])
        #expect(Self.split(calls, window: .twoHours).shown.map(\.objectID) == [1, 2, 3])
    }

    @Test("nothing older than the window means nothing to fold")
    func anEmptyFold() {
        // Which is the ordinary case on a quiet night, and the reason the fold's group has to be able to
        // disappear rather than showing an empty box.
        let result = Self.split([Self.call(1, minutesAgo: 5)])
        #expect(result.folded.isEmpty)
    }

    @Test("the Service's order survives the split")
    func theOrderIsNotRearranged() {
        // The list arrives newest first and neither half is re-sorted. An old critical is *shown*, not
        // promoted: it keeps its place among the recent ones rather than jumping the queue.
        let calls = [
            Self.call(1, minutesAgo: 5),
            Self.call(2, minutesAgo: 180, code: "SHO"),
            Self.call(3, minutesAgo: 190),
            Self.call(4, minutesAgo: 200, code: "STA"),
        ]
        let result = Self.split(calls)

        #expect(result.shown.map(\.objectID) == [1, 2, 4])
        #expect(result.folded.map(\.objectID) == [3])
    }
}
