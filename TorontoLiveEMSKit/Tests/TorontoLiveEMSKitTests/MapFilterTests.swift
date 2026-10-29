import Testing

import TorontoLiveEMSKit

/// Which feeds the map draws.
@Suite("Map filter")
struct MapFilterTests {

    private static func mark(_ source: IncidentMark.Source) -> IncidentMark {
        IncidentMark(source: source, category: .other, urgency: .routine)
    }

    @Test("showing both keeps both")
    func allKeepsEverything() {
        #expect(MapFilter.all.keeps(Self.mark(.fire)))
        #expect(MapFilter.all.keeps(Self.mark(.police)))
    }

    @Test("each source filter keeps that source and nothing else")
    func eachFilterKeepsItsOwn() {
        #expect(MapFilter.fire.keeps(Self.mark(.fire)))
        #expect(!MapFilter.fire.keeps(Self.mark(.police)))
        #expect(MapFilter.police.keeps(Self.mark(.police)))
        #expect(!MapFilter.police.keeps(Self.mark(.fire)))
    }

    @Test("the filter asks about the source, never the kind or the severity")
    func theFilterIgnoresEverythingElse() {
        // The one thing this must not become. A filter that quietly depended on a kind or an urgency
        // would change what a reader sees when the colour rules changed, which is nobody's intent.
        for kind in IncidentMark.Category.allCases {
            for urgency in IncidentMark.Urgency.allCases {
                let police = IncidentMark(source: .police, category: kind, urgency: urgency)
                #expect(MapFilter.fire.keeps(police) == false)
                #expect(MapFilter.police.keeps(police))
                #expect(MapFilter.all.keeps(police))
            }
        }
    }

    @Test("every option has a name and a glyph")
    func everyOptionIsLabelled() {
        for option in MapFilter.allCases {
            #expect(!option.label.isEmpty, "\(option) has no name")
            #expect(!option.systemImage.isEmpty, "\(option) has no glyph")
        }
        #expect(
            MapFilter.allCases.count == 3,
            "a fourth row would have to answer the same question as the other three"
        )

        // The short words are what the button says, so they must be three words and not one word three
        // times — a control that cannot be told apart by reading it is not a control.
        #expect(Set(MapFilter.allCases.map(\.shortLabel)).count == 3)
        #expect(MapFilter.allCases.allSatisfy { !$0.shortLabel.isEmpty && $0.shortLabel.count <= 6 })
    }
}
