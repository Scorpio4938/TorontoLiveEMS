import Foundation
import Testing

import TorontoLiveEMSKit

#if canImport(UIKit)
import UIKit
#endif

/// The marks the map draws, and the one vocabulary both feeds share.
@Suite("Incident marks")
struct IncidentMarkTests {

    /// A fire incident whose published type is one the City's own table knows.
    ///
    /// `Fire - Residential` and `Medical` are keys in that table rather than invented here: a fixture
    /// the City has never published would test the fallback in every test that used it.
    private static func incident(
        type: String,
        alarmLevel: String = "1"
    ) -> Incident {
        Incident(
            incidentNumber: "F26000001",
            primeStreet: "QUEEN ST E",
            crossStreets: nil,
            dispatchTime: "2026-10-05T12:54:19",
            incidentType: type,
            alarmLevel: alarmLevel,
            area: "Station 1",
            dispatchedUnits: nil
        )
    }

    // MARK: - The projection

    @Test("every fine fire category lands in a coarse one")
    func everyFireCategoryProjects() {
        // The projection has to be total. A category with nowhere to go would be a mark that never
        // draws, and nothing would fail: the switch is exhaustive over the enum, so this walks all
        // thirteen to check each one lands on something a symbol exists for.
        for category in IncidentCategory.allCases {
            let projected = IncidentMark.Category(incidentCategory: category)
            #expect(
                IncidentMark.Category.allCases.contains(projected),
                "\(category) projected to something outside the coarse set"
            )
        }
    }

    @Test("the coarse set really is coarser")
    func theProjectionIsCoarser() {
        // Nine from thirteen, and being fewer is the whole point: the reason for a shared vocabulary
        // is that a symbol per published type would be a legend nobody could learn. A projection that
        // collided nothing would mean thirteen shapes to find rather than nine.
        let projected = Set(IncidentCategory.allCases.map(IncidentMark.Category.init(incidentCategory:)))
        #expect(projected.count < IncidentCategory.allCases.count)
    }

    @Test("the five hazards share one shape")
    func hazardsShareAShape() {
        // Stated on its own because it is the judgement inside the projection, and the one most likely
        // to be argued with: to a reader, a gas leak and wires down give the same instruction.
        for category in [IncidentCategory.carbonMonoxide, .hazmat, .gasLeak, .water, .wiresDown] {
            #expect(IncidentMark.Category(incidentCategory: category) == .hazard)
        }
    }

    @Test("a fire incident's mark comes from the City's published type")
    func fireIncidentsProjectFromTheirPublishedType() {
        #expect(IncidentMark(incident: Self.incident(type: "Fire - Residential")).category == .fire)
        #expect(IncidentMark(incident: Self.incident(type: "Medical")).category == .medical)
        #expect(IncidentMark(incident: Self.incident(type: "Fire - Residential")).source == .fire)
    }

    @Test("a type the City never published is marked unknown rather than dropped")
    func unknownTypesLandInOther() {
        // The map has to draw something, and "we do not know what this is" is a truer mark than a gap
        // where a mark should be.
        let mark = IncidentMark(incident: Self.incident(type: "Not - A - Published - Type"))
        #expect(mark.category == .other)
    }

    // MARK: - What the colour is allowed to mean

    @Test("attention is the incident's rule, not a re-reading of its category")
    func attentionComesFromTheIncident() {
        // A mark that derived this from its category alone would call a major response to an ordinary
        // medical call nothing to look at. The incident's own rule weighs the Alarm Level as well,
        // which is why the mark carries the answer rather than working it out again.
        let quiet = Self.incident(type: "Medical", alarmLevel: "1")
        #expect(!IncidentMark(incident: quiet).warrantsAttention)

        let escalated = Self.incident(type: "Medical", alarmLevel: "2")
        #expect(IncidentMark(incident: escalated).warrantsAttention)
    }

    @Test("a fire is urgent without needing an alarm level")
    func dangerousCategoriesAreUrgentOnTheirOwn() {
        let fire = Self.incident(type: "Fire - Residential", alarmLevel: "1")
        #expect(IncidentMark(incident: fire).warrantsAttention)
    }

    // MARK: - What the filter will read, and what the marks look like

    @Test("a source carries the name the filter shows")
    func sourceLabelsArePinned() {
        #expect(IncidentMark.Source.fire.label == "Fire")
        #expect(IncidentMark.Source.police.label == "Police")
        #expect(IncidentMark.Source.allCases.count == 2, "a third source would need a filter option")
    }

    @Test("every category has a symbol, and no two share one")
    func everyCategoryHasItsOwnSymbol() {
        let symbols = IncidentMark.Category.allCases.map(\.symbol)
        #expect(symbols.allSatisfy { !$0.isEmpty })
        #expect(
            Set(symbols).count == symbols.count,
            "two kinds wearing one shape are two kinds a reader cannot tell apart"
        )
    }

    #if canImport(UIKit)
    @Test("every symbol the marks use exists in the system's own catalogue")
    func symbolsExist() {
        // **A missing symbol is silence, not an error.** `Image(systemName:)` draws nothing whatever
        // for a name the system does not know: no build failure, no placeholder, just a gap where a
        // mark should be. So the names are asked of the catalogue instead of trusted — which needs a
        // system that has one. Under `swift test` on a Mac this does not compile in at all; under ⌘U
        // with an iOS destination it does, and that is where it is meant to run.
        for category in IncidentMark.Category.allCases {
            #expect(
                UIImage(systemName: category.symbol) != nil,
                "\(category.symbol) is not a symbol this system knows"
            )
        }
    }
    #endif
}
