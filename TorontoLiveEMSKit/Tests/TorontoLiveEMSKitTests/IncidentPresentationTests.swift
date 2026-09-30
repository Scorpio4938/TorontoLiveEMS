import Testing
import TorontoLiveEMSKit

@Suite("Incident presentation")
struct IncidentPresentationTests {

    @Test("offers exactly two arrangements")
    func twoArrangements() {
        // Both are whole-list layouts showing the same five fields. A third would have to
        // be a third shape, not a third set of typographic settings — two of those were
        // tried and could not be told apart from the table.
        #expect(IncidentPresentation.allCases == [.compactTable, .cards])
    }

    @Test("names itself for the setting that picks it")
    func everyCaseHasALabel() {
        for presentation in IncidentPresentation.allCases {
            #expect(!presentation.label.isEmpty)
        }
        #expect(IncidentPresentation.compactTable.label == "Table")
        #expect(IncidentPresentation.cards.label == "Cards")
    }

    @Test("gives each arrangement a name of its own")
    func labelsAreDistinct() {
        // They are the two options of a picker, and the picker draws them from here. Two
        // cases sharing a name would show the reader the same choice twice, with nothing
        // but the stored value to tell them apart.
        let labels = IncidentPresentation.allCases.map { $0.label }
        #expect(Set(labels).count == labels.count)
    }

    @Test("keeps a stable stored value for each")
    func storedValuesAreStable() {
        // These strings live in the reader's preferences. Renaming one silently resets the
        // setting for everyone who has already chosen, with no error and no way to notice.
        #expect(IncidentPresentation.compactTable.rawValue == "compactTable")
        #expect(IncidentPresentation.cards.rawValue == "cards")
    }

    @Test("opens on cards")
    func standardIsCards() {
        // Chosen rather than derived, and it costs density: cards show fewer incidents at once
        // than the table does. That is the trade, made on purpose. It lives in the package
        // rather than as a default in two views precisely so that this test can exist.
        //
        // Not asserted against a position in `allCases`. Where a case sits in that list is
        // incidental, and pinning the default to a position would make reordering the list a
        // silent change of default.
        #expect(IncidentPresentation.standard == .cards)
    }

    @Test("survives a round trip through the stored value")
    func roundTripsThroughStorage() {
        // What @AppStorage does with it on every launch.
        for presentation in IncidentPresentation.allCases {
            #expect(IncidentPresentation(rawValue: presentation.rawValue) == presentation)
        }
    }
}
