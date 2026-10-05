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

    @Test("severity is the incident's rule, not a re-reading of its category")
    func severityComesFromTheIncident() {
        // A mark deriving this from its category alone would call a major response to an ordinary
        // medical call nothing to look at. The severity weighs the Alarm Level too, which is why the
        // mark carries the answer rather than working it out again — and it is two steps rather than a
        // flag now, so the escalation has somewhere to land other than in with the fires.
        let quiet = Self.incident(type: "Medical", alarmLevel: "1")
        #expect(IncidentMark(incident: quiet).urgency == .routine)

        let escalated = Self.incident(type: "Medical", alarmLevel: "2")
        #expect(IncidentMark(incident: escalated).urgency == .elevated)
    }

    @Test("a fire is critical without needing an alarm level")
    func dangerousCategoriesAreCriticalOnTheirOwn() {
        let fire = Self.incident(type: "Fire - Residential", alarmLevel: "1")
        #expect(IncidentMark(incident: fire).urgency == .critical)
    }

    @Test("the severities are ordered, and unknown is not the least serious")
    func severitiesHaveAnOrder() {
        // The order exists to choose between two records at one place. `unknown` sits last without
        // being a claim about danger: where two calls share a point, one that says something beats one
        // that says nothing.
        #expect(IncidentMark.Urgency.critical.rank < IncidentMark.Urgency.elevated.rank)
        #expect(IncidentMark.Urgency.elevated.rank < IncidentMark.Urgency.routine.rank)
        #expect(IncidentMark.Urgency.routine.rank < IncidentMark.Urgency.unknown.rank)
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

    // MARK: - The police side

    private static func call(code: String) -> PoliceCall {
        PoliceCall(
            objectID: 1,
            occurrenceTime: Date(timeIntervalSince1970: 1_791_219_259),
            division: "D14",
            latitude: 43.66,
            longitude: -79.42,
            callTypeCode: code,
            callType: "AS THE SERVICE SENT IT",
            crossStreets: nil
        )
    }

    @Test("every code in the app's own list has a kind")
    func everyDocumentedCodeHasAMapping() {
        // **The test that keeps the table honest.** `from(callTypeCode:)` answers `nil` for a code it
        // does not know — the right answer for one the Service has started using since, and the wrong
        // answer for one the app itself lists. Walking the list means adding a code forces a decision
        // about where it belongs instead of leaving it quietly unknown.
        for type in PoliceCallType.documented {
            #expect(
                IncidentMark.Category.from(callTypeCode: type.code) != nil,
                "\(type.code) (\(type.name)) is in the app's list but maps to no kind"
            )
        }
    }

    @Test("the police codes land where their words say")
    func policeCodesMapToTheirKinds() {
        let expected: [(String, IncidentMark.Category)] = [
            ("FIR", .fire),
            ("FIRAL", .alarm),
            ("SEEAM", .medical),
            ("MISVU", .rescue),
            ("HAZ", .hazard),
            ("PIACC", .traffic),
            ("IMPDR", .traffic),
            ("PERGU", .crime),
            ("ASSPR", .crime),
            ("DIS", .disturbance),
            ("FIG", .disturbance),
            ("FOUPR", .other),
        ]
        for (code, kind) in expected {
            #expect(IncidentMark(call: Self.call(code: code)).category == kind, "\(code)")
        }
    }

    @Test("an unknown trouble is left unknown")
    func anUnknownTroubleStaysUnknown() {
        // The Service's own word for it is that it does not know. `.disturbance` would be this app
        // answering a question the Service left open.
        #expect(IncidentMark(call: Self.call(code: "UNKTR")).category == .other)
    }

    @Test("a code the Service starts using is unknown, not guessed at")
    func anUnseenCodeIsNotGuessedAt() {
        #expect(IncidentMark.Category.from(callTypeCode: "BRANDNEW") == nil)
        #expect(IncidentMark(call: Self.call(code: "BRANDNEW")).category == .other)
    }

    @Test("a police call's severity is inferred from its code, and inferred here")
    func policeSeverityIsInferred() {
        // **This reverses an earlier decision, deliberately and on the reader's instruction.** The
        // Service publishes no severity for a call, and an earlier version of this file refused to
        // supply one — which was honest and useless, because an assault and a found bicycle then looked
        // identical on the map. What is left is an inference, made here rather than by the Service, and
        // written down where it can be argued with. The three spot checks below are the argument in
        // miniature: violence where somebody may be in danger now, violence that has already happened,
        // and an ordinary call.
        #expect(IncidentMark(call: Self.call(code: "PERGU")).urgency == .critical)
        #expect(IncidentMark(call: Self.call(code: "ASSPR")).urgency == .critical)
        #expect(IncidentMark(call: Self.call(code: "ASS")).urgency == .elevated)
        #expect(IncidentMark(call: Self.call(code: "DIS")).urgency == .routine)

        // The twelve that arrived in a later window, of which two were seen on a map as question marks.
        #expect(IncidentMark(call: Self.call(code: "ROB")).category == .crime)
        #expect(IncidentMark(call: Self.call(code: "ROB")).urgency == .elevated)
        #expect(IncidentMark(call: Self.call(code: "PERKN")).category == .crime)
        #expect(IncidentMark(call: Self.call(code: "PERKN")).urgency == .critical)
        #expect(IncidentMark(call: Self.call(code: "MISCH")).category == .rescue)
        #expect(IncidentMark(call: Self.call(code: "MISCH")).urgency == .critical)
        #expect(IncidentMark(call: Self.call(code: "TRAOB")).category == .traffic)
        #expect(IncidentMark(call: Self.call(code: "TRAOB")).urgency == .routine)
    }

    @Test("a call nobody named is unknown, not ordinary")
    func anUnnamedCallIsUnknown() {
        // The Service's own word for `UNKTR` is that it does not know; for a code it has started using
        // since, it is this app that does not. Both are `.unknown` rather than `.routine`, because "we
        // cannot say how serious this is" is a different claim from "this is ordinary".
        #expect(IncidentMark(call: Self.call(code: "UNKTR")).urgency == .unknown)
        #expect(IncidentMark(call: Self.call(code: "BRANDNEW")).urgency == .unknown)
    }

    @Test("every code in the app's list has a severity")
    func everyDocumentedCodeHasASeverity() {
        // The table has a default, so an unmapped code is not a crash — it is `.unknown`. That is the
        // right answer for a code the Service has just started using and the wrong one for a code the
        // app itself lists, so the list is walked: adding a code forces a decision about how serious it
        // is, rather than quietly filing it as unknown.
        for type in PoliceCallType.documented {
            #expect(
                IncidentMark.Urgency(callTypeCode: type.code) != .unknown || type.code == "UNKTR",
                "\(type.code) (\(type.name)) fell through to unknown"
            )
        }
    }

    @Test("between the two feeds, every kind is used")
    func bothFeedsJustifyTheWholeSet() {
        // Nine kinds is a claim about the data: a kind nothing uses would be a symbol nobody ever
        // sees. The fire side reaches seven of the nine, and the police side supplies the two it
        // cannot reach — which is the reason for a shared vocabulary rather than a fire one with two
        // extra cases bolted on.
        var used = Set(IncidentCategory.allCases.map(IncidentMark.Category.init(incidentCategory:)))
        used.formUnion(
            PoliceCallType.documented.compactMap {
                IncidentMark.Category.from(callTypeCode: $0.code)
            }
        )
        #expect(used.count == IncidentMark.Category.allCases.count)
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
        // And the chrome's, which are drawn in a capsule rather than on the map: the filter's three, and
        // the map kinds' two. These are the ones a change of mind edits — `map.fill` became `map` the
        // day the standard kind's glyph was looked at on a device — so they are the ones most worth
        // asking the catalogue about.
        for option in MapFilter.allCases {
            #expect(
                UIImage(systemName: option.systemImage) != nil,
                "\(option.systemImage) is not a symbol this system knows"
            )
        }
        for kind in MapKind.allCases {
            #expect(
                UIImage(systemName: kind.systemImage) != nil,
                "\(kind.systemImage) is not a symbol this system knows"
            )
        }
    }
    #endif

    // MARK: - What the legend shows

    @Test("every kind and every severity has something to say for itself")
    func theLegendHasNoBlankRows() {
        // The map's information screen renders these directly, so an empty one would be a blank line in
        // a legend a reader is looking at to find out what a symbol means.
        for kind in IncidentMark.Category.allCases {
            #expect(!kind.label.isEmpty, "\(kind) has no name")
            #expect(!kind.note.isEmpty, "\(kind) has no description")
            #expect(!kind.symbol.isEmpty, "\(kind) has no symbol")
        }
        for urgency in IncidentMark.Urgency.allCases {
            #expect(!urgency.label.isEmpty, "\(urgency) has no name")
            #expect(!urgency.fireRule.isEmpty, "\(urgency) has no description")
        }
    }

    @Test("the legend's police codes come from the tables, one severity each")
    func theLegendListsEachPoliceCodeOnce() {
        // The screen does not carry a copy of the mapping — it filters the documented list by what the
        // code table says. This asserts that the result is a partition: every code appears under exactly
        // one severity, and none is left out of the legend entirely.
        var seen: [String: Int] = [:]
        for urgency in IncidentMark.Urgency.allCases {
            for type in PoliceCallType.documented
            where IncidentMark.Urgency(callTypeCode: type.code) == urgency {
                seen[type.code, default: 0] += 1
            }
        }
        #expect(seen.count == PoliceCallType.documented.count, "a documented code is in no severity")
        #expect(seen.values.allSatisfy { $0 == 1 }, "a documented code is in more than one severity")
    }
}
