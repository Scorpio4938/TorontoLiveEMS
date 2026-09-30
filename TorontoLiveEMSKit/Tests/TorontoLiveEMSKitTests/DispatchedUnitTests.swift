import Testing
import TorontoLiveEMSKit

@Suite("Dispatched units")
struct DispatchedUnitTests {

    @Test("names apparatus using the City's own legend")
    func decodesTheLegend() {
        #expect(DispatchedUnit(code: "P231").display == "Pumper 231")
        #expect(DispatchedUnit(code: "R346").display == "Rescue 346")
        #expect(DispatchedUnit(code: "A231").display == "Aerial 231")
        #expect(DispatchedUnit(code: "T333").display == "Tower 333")
        #expect(DispatchedUnit(code: "S143").display == "Squad 143")
        #expect(DispatchedUnit(code: "LA231").display == "Air Light 231")
        #expect(DispatchedUnit(code: "C22").display == "Chief 22")
        #expect(DispatchedUnit(code: "HZ1").display == "HazMat 1")
        #expect(DispatchedUnit(code: "HR12").display == "Highrise 12")
        #expect(DispatchedUnit(code: "WT9").display == "Water Tanker 9")
    }

    @Test("prefers the longest matching code")
    func longestCodeWins() {
        // Without longest-first matching these decode as Pumper, Chief and Squad.
        #expect(DispatchedUnit(code: "PL231").display == "Platform 231")
        #expect(DispatchedUnit(code: "CMD1").display == "Command Vehicle 1")
        #expect(DispatchedUnit(code: "TRS2").display == "Trench Rescue Support 2")
    }

    @Test("uses the City's own wording, not a tidier paraphrase")
    func usesCityWording() {
        // The City's legend says "Canteen vehicle". These codes also contain digits,
        // so they exercise the code/exactly-station split.
        #expect(DispatchedUnit(code: "Sup7").display == "Canteen vehicle 7")
        #expect(DispatchedUnit(code: "Box12").display == "Canteen vehicle 12")
    }

    @Test("splits a roster into units")
    func splitsARoster() {
        let units = DispatchedUnit.roster(from: "P231, P234")

        #expect(units.count == 2)
        #expect(units.map(\.display) == ["Pumper 231", "Pumper 234"])
    }

    @Test("reads a large response")
    func readsALargeResponse() {
        let units = DispatchedUnit.roster(
            from: "A221, A233, C22, C24, LA231, P222, P224, R235, S313"
        )

        #expect(units.count == 9)
        #expect(units.first?.display == "Aerial 221")
        #expect(units.last?.display == "Squad 313")
    }

    @Test("is empty when the feed published no roster")
    func noPublishedRoster() {
        // The feed omits the element entirely for roughly one incident in five.
        #expect(DispatchedUnit.roster(from: nil).isEmpty)
        #expect(DispatchedUnit.roster(from: "").isEmpty)
    }

    @Test("leaves a code it cannot decode exactly as published")
    func unknownCodeStaysRaw() {
        // The City's legend is not provably exhaustive; `L` is undefined in it.
        let unit = DispatchedUnit(code: "L325")

        #expect(unit.apparatus == nil)
        #expect(unit.station == "325")
        #expect(unit.display == "L325")
    }

    @Test("keeps an undecodable code inside an otherwise readable roster")
    func keepsUnknownCodeInARoster() {
        let units = DispatchedUnit.roster(from: "L325, R325")

        #expect(units.map(\.display) == ["L325", "Rescue 325"])
    }

    @Test("offers the legend in the order a reader looks something up")
    func legendHasAReadingOrder() {
        // The list it comes from is ordered longest-code-first, because prefix matching needs
        // it that way; this is the same list read by a person, so it is sorted by name.
        let names = DispatchedUnit.documentedApparatus.map(\.name)
        #expect(!names.isEmpty)
        #expect(names == names.sorted())

        // And every entry really is the City's legend, not a second copy of it. Two codes
        // share a name — `Box12` and `Sup7` are both Canteen vehicles — so the code is what
        // identifies an entry, and it has to be unique for a list to render from it.
        let codes = DispatchedUnit.documentedApparatus.map(\.code)
        #expect(Set(codes).count == codes.count)
        for entry in DispatchedUnit.documentedApparatus {
            #expect(DispatchedUnit(code: entry.code + "231").apparatus == entry.name)
        }
    }
}
