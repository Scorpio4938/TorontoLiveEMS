import Testing
import TorontoLiveEMSKit

@Suite("Postal-area locations")
struct IncidentLocationTests {

    private func incident(primeStreet: String?) -> Incident {
        return Incident(
            incidentNumber: "F0",
            primeStreet: primeStreet,
            crossStreets: nil,
            dispatchTime: "2026-09-29T18:24:39",
            incidentType: "MEDICAL",
            alarmLevel: "0",
            area: "426",
            dispatchedUnits: nil
        )
    }

    @Test("recognises a published postal area")
    func recognisesPostalArea() {
        #expect(incident(primeStreet: "M6K").isLocationPostalArea)
        #expect(incident(primeStreet: "M5T").isLocationPostalArea)
    }

    @Test("does not mistake a street name for a postal area")
    func rejectsStreetNames() {
        #expect(!incident(primeStreet: "LAWRENCE AVE, SC").isLocationPostalArea)
        #expect(!incident(primeStreet: "KING ST").isLocationPostalArea)
        #expect(!incident(primeStreet: "M6").isLocationPostalArea)
        #expect(!incident(primeStreet: "MEDICAL").isLocationPostalArea)
        #expect(!incident(primeStreet: nil).isLocationPostalArea)
    }

    @Test("agrees with the captured feed")
    func agreesWithTheCapturedFeed() throws {
        let snapshot = try LiveCADParser.parse(Fixtures.liveSnapshotData)

        let medical = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154815" }
        )
        let addressable = try #require(
            snapshot.incidents.first { $0.incidentNumber == "F26154871" }
        )

        #expect(medical.isLocationPostalArea)
        #expect(!addressable.isLocationPostalArea)
    }
}

@Suite("Where an incident is")
struct IncidentPlacementTests {

    private func place(
        primeStreet: String? = nil,
        crossStreets: String? = nil
    ) -> Incident {
        Incident(
            incidentNumber: "F26154815",
            primeStreet: primeStreet,
            crossStreets: crossStreets,
            dispatchTime: "2026-09-29T18:24:39",
            incidentType: "MEDICAL",
            alarmLevel: "0",
            area: "426",
            dispatchedUnits: nil
        )
    }

    @Test("prefers the intersection, because it is the more precise one")
    func intersectionWins() {
        // The app shows Prime Street as *the* location in its list, so this looks backwards.
        // It is not: an addressable incident publishes both, and two crossing streets name a
        // place where one street name names a road.
        let location = IncidentLocation.from(place(
            primeStreet: "LAWRENCE AVE, SC",
            crossStreets: "WOODBINE AVE / KINGSTON RD"
        ))
        #expect(location == .intersection("WOODBINE AVE / KINGSTON RD"))
        #expect(!location.isArea)
    }

    @Test("falls back to the street when there is no intersection")
    func streetWhenAlone() {
        #expect(IncidentLocation.from(place(primeStreet: "QUEEN ST W")) == .street("QUEEN ST W"))
    }

    @Test("treats a postal area as an area, not a point")
    func postalAreaIsAnArea() {
        // A medical incident's location is published as an FSA to preserve privacy. Drawing it
        // as a pin would put it at the centre of a neighbourhood and call that a location,
        // which is the narrowing ADR-0004 forbids.
        let location = IncidentLocation.from(place(primeStreet: "M6K"))
        #expect(location == .postalArea("M6K"))
        #expect(location.isArea)
    }

    @Test("has nothing to look up when nothing was published")
    func nothingPublished() {
        let location = IncidentLocation.from(place())
        #expect(location == .unpublished)
        #expect(location.query == nil)
    }

    @Test("is not fooled by a value that is only punctuation")
    func punctuationIsNotALocation() {
        // The feed publishes a lone slash for an intersection it will not give, and this is the
        // shape that reached a build once already after the parser stopped treating it as empty.
        // The parser catches it first; `Incident` is public, so this catches it second.
        #expect(IncidentLocation.from(place(crossStreets: " / ")) == .unpublished)
        #expect(IncidentLocation.from(place(primeStreet: " / ")) == .unpublished)
        #expect(IncidentLocation.from(place(primeStreet: "", crossStreets: "")) == .unpublished)
    }

    @Test("drops the City's former municipality from what it looks up")
    func stripsMunicipality() {
        // `SC` is Scarborough, part of Toronto since 1998. A geocoder is not interested in the
        // 1998 answer, and `LAWRENCE AVE, SC, Toronto` is a worse question than the one without.
        #expect(IncidentLocation.from(place(primeStreet: "LAWRENCE AVE, SC")) == .street("LAWRENCE AVE"))
        #expect(IncidentLocation.from(place(primeStreet: "FRONT ST, TT")) == .street("FRONT ST"))
        #expect(IncidentLocation.from(place(primeStreet: "SHEPPARD AVE, NY")) == .street("SHEPPARD AVE"))
    }

    @Test("leaves a street that has no municipality alone")
    func leavesPlainStreetsAlone() {
        #expect(IncidentLocation.from(place(primeStreet: "QUEEN ST W")) == .street("QUEEN ST W"))
        // Not a municipality code, so not stripped — two letters is the shape, not any suffix.
        #expect(IncidentLocation.from(place(primeStreet: "BAY ST, AB")) == .street("BAY ST"))
        #expect(IncidentLocation.from(place(primeStreet: "MAIN ST, ABC")) == .street("MAIN ST, ABC"))
        #expect(IncidentLocation.from(place(primeStreet: "MAIN ST, 12")) == .street("MAIN ST, 12"))
    }

    @Test("asks the geocoder a question that can only mean Toronto")
    func queriesAreLocalised() {
        // The feed is Toronto-only. A bare `QUEEN ST W` geocodes confidently to the wrong
        // continent, and a geocoder that answers wrongly is worse than one that does not answer.
        #expect(IncidentLocation.intersection("A ST / B ST").query == "A ST & B ST, Toronto, Ontario")
        #expect(IncidentLocation.street("QUEEN ST W").query == "QUEEN ST W, Toronto, Ontario")
        #expect(IncidentLocation.postalArea("M6K").query == "M6K, Toronto, Ontario")
    }

    @Test("asks for an intersection the way a geocoder reads one")
    func intersectionsAreAskedWithAnAmpersand() {
        // The feed's own separator is a slash — `WOODBINE AVE / KINGSTON RD` is what the City
        // publishes. It was being passed through unchanged, which is the published form and not a
        // question any geocoder was ever asked to answer.
        //
        // Through `query`, not through the helper that builds it: what the app asks is the part
        // worth promising.
        #expect(IncidentLocation.intersection("WOODBINE AVE / KINGSTON RD").query
            == "WOODBINE AVE & KINGSTON RD, Toronto, Ontario")
        // The real intersections in the live capture, which is where the spacing actually varies.
        #expect(IncidentLocation.intersection("ARDAGH ST / JANE ST").query
            == "ARDAGH ST & JANE ST, Toronto, Ontario")
        #expect(IncidentLocation.intersection("A ST/B ST").query == "A ST & B ST, Toronto, Ontario")
        #expect(IncidentLocation.intersection("A ST  /  B ST").query == "A ST & B ST, Toronto, Ontario")
        // House numbers on both sides of a corner are still two street names.
        #expect(IncidentLocation.intersection("3950 LAWRENCE AVE E / 3967 LAWRENCE AVE E").query
            == "3950 LAWRENCE AVE E & 3967 LAWRENCE AVE E, Toronto, Ontario")
    }

    @Test("leaves an intersection it cannot parse exactly as published")
    func unparseableIntersectionsAreLeftAlone() {
        // Guessing at a value that does not have the shape is worse than passing it through: a
        // wrong guess fails somewhere else, silently.
        #expect(IncidentLocation.intersection("A ST / B ST / C ST").query
            == "A ST / B ST / C ST, Toronto, Ontario")
        #expect(IncidentLocation.intersection("JANE ST").query == "JANE ST, Toronto, Ontario")
        #expect(IncidentLocation.intersection("A ST / ").query == "A ST / , Toronto, Ontario")
        #expect(IncidentLocation.intersection("/ B ST").query == "/ B ST, Toronto, Ontario")
        // Two separators with nothing between them is not two streets.
        #expect(IncidentLocation.intersection(" / ").query == " / , Toronto, Ontario")
    }

    @Test("calls only a postal area an area")
    func onlyPostalAreasAreAreas() {
        #expect(IncidentLocation.postalArea("M6K").isArea)
        #expect(!IncidentLocation.intersection("A ST / B ST").isArea)
        #expect(!IncidentLocation.street("QUEEN ST W").isArea)
        #expect(!IncidentLocation.unpublished.isArea)
    }
}

@Suite("What the colour rule marks")
struct IncidentAttentionTests {

    private func attention(type: String, level: String) -> Bool {
        Incident(
            incidentNumber: "F1",
            primeStreet: "QUEEN ST W",
            crossStreets: nil,
            dispatchTime: "2026-09-29T18:24:39",
            incidentType: type,
            alarmLevel: level,
            area: "426",
            dispatchedUnits: nil
        ).warrantsAttention
    }

    @Test("marks a dangerous category and an escalation, and neither on its own account")
    func theRuleIsTwoConditions() {
        // The map, Incident Type and Alarm Level all read this now. Before it was written down
        // as one rule it was stated twice — once per column — which is how two columns come to
        // disagree about what matters.
        #expect(attention(type: "Fire - Residential", level: "0"))
        #expect(attention(type: "MEDICAL", level: "2"))
        #expect(!attention(type: "MEDICAL", level: "0"))
        #expect(!attention(type: "Alarm Single Source", level: "0"))
    }

    @Test("is not fooled by a type it cannot categorise")
    func unknownTypesAreNotMarked() {
        #expect(!attention(type: "Hovercraft - Inverted", level: "0"))
    }
}
