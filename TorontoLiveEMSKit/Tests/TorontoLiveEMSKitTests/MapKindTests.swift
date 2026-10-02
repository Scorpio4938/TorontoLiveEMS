import Testing

import TorontoLiveEMSKit

/// The stored map kinds, and the two things about them that can go wrong without a symptom.
@Suite("Map kinds")
struct MapKindTests {

    @Test("the stored keys are what they were")
    func rawValuesAreStable() {
        // These strings are the keys `@AppStorage` writes. Renaming a case changes its raw value
        // and silently resets the choice of everyone who had made one — no error, no crash, just a
        // map that went back to standard the next time the app opened. So the values are pinned.
        #expect(MapKind.standard.rawValue == "standard")
        #expect(MapKind.imagery.rawValue == "imagery")
        #expect(MapKind.hybrid.rawValue == "hybrid")
        #expect(MapKind.allCases.count == 3, "three kinds, because MapKit has three styles")
    }

    @Test("every kind has a name and a glyph of its own")
    func labelsAndGlyphsAreDistinct() {
        let labels = MapKind.allCases.map(\.label)
        let glyphs = MapKind.allCases.map(\.systemImage)

        #expect(labels.allSatisfy { !$0.isEmpty })
        #expect(glyphs.allSatisfy { !$0.isEmpty })
        // Two kinds sharing either one makes the control unable to say which map is in force —
        // which is the entire job of the button.
        #expect(Set(labels).count == labels.count, "two kinds share a name: \(labels)")
        #expect(Set(glyphs).count == glyphs.count, "two kinds share a glyph: \(glyphs)")
    }
}
