import Testing
import TorontoLiveEMSKit

/// The compact table's column set and the values it draws.
///
/// These live in the package because the columns are content, not layout — mapping an
/// Incident to the strings and flags a cell shows. What is *not* covered here is the
/// table's appearance: its measurements are `CompactTable` in the app target, and how
/// they render is checked by looking at it.
@Suite("Compact table columns")
struct CompactColumnTests {

    private func incident(
        primeStreet: String? = "QUEEN ST W",
        dispatchTime: String = "2026-09-29T18:24:39",
        incidentType: String = "MEDICAL",
        alarmLevel: String = "0",
        dispatchedUnits: String? = "P231, P234"
    ) -> Incident {
        Incident(
            incidentNumber: "F26154815",
            primeStreet: primeStreet,
            crossStreets: nil,
            dispatchTime: dispatchTime,
            incidentType: incidentType,
            alarmLevel: alarmLevel,
            area: "426",
            dispatchedUnits: dispatchedUnits
        )
    }

    @Test("is fixed at five columns, in the order they are shown")
    func columnSetAndOrder() {
        // Order is load-bearing. The header and every row iterate allCases in step, so
        // reordering this list silently relabels both grids at once and still compiles.
        #expect(CompactColumn.allCases == [
            .primeStreet,
            .dispatchTime,
            .incidentType,
            .alarmLevel,
            .dispatchedUnits,
        ])
    }

    @Test("leaves Cross Street to the detail view")
    func crossStreetIsNotAColumn() {
        // Cross Street is in the feed and is deliberately not a column: it is blank on
        // most incidents — every medical one — and is a refinement of Prime Street
        // rather than a peer of it, so on a phone it spent width it rarely used. A test
        // rather than a comment because adding it back is a decision, not an oversight.
        let labels = CompactColumn.allCases.map { $0.label.lowercased() }
        #expect(!labels.contains { $0.contains("cross") })
    }

    @Test("every column names itself")
    func everyColumnHasALabel() {
        for column in CompactColumn.allCases {
            #expect(!column.label.isEmpty)
        }
    }

    @Test("shows the prime street exactly as published")
    func primeStreetIsPublished() {
        let cell = CompactColumn.primeStreet.cell(for: incident(), timeFormat: .twelveHour)
        #expect(cell.text == "QUEEN ST W")
        #expect(!cell.warrantsAttention)
    }

    @Test("leaves a cell empty when the feed published nothing")
    func unpublishedPrimeStreetIsEmpty() {
        // The feed sends an XML-escaped space for a location it will not publish, and
        // the parser turns all three "not published" shapes into nil. The cell renders
        // nil as empty — no placeholder, no substitute.
        let cell = CompactColumn.primeStreet.cell(
            for: incident(primeStreet: nil),
            timeFormat: .twelveHour
        )
        #expect(cell.text == nil)
    }

    @Test("renders the dispatch time in the reader's chosen clock")
    func dispatchTimeFollowsTheSetting() {
        let twelve = CompactColumn.dispatchTime.cell(
            for: incident(),
            timeFormat: .twelveHour
        )
        let twentyFour = CompactColumn.dispatchTime.cell(
            for: incident(),
            timeFormat: .twentyFourHour
        )
        #expect(twelve.text == "6:24 PM")
        #expect(twentyFour.text == "18:24")
    }

    @Test("renders Incident Type as its category, not the published string")
    func incidentTypeIsCategorised() {
        // Width is the reason. `Vehicle - Personal Injury` is 26 characters in a column
        // that has room for about 11.
        let cell = CompactColumn.incidentType.cell(
            for: incident(incidentType: "Vehicle - Personal Injury"),
            timeFormat: .twelveHour
        )
        #expect(cell.text == "Vehicle")
    }

    @Test("falls back to the published string for a type we cannot categorise")
    func unknownIncidentTypeFallsBack() {
        // Degrading to the raw value is the point: a type the City adds later shows up
        // unreadable-but-correct rather than missing.
        let cell = CompactColumn.incidentType.cell(
            for: incident(incidentType: "Hovercraft - Inverted"),
            timeFormat: .twelveHour
        )
        #expect(cell.text == "Hovercraft - Inverted")
        #expect(!cell.warrantsAttention)
    }

    @Test("marks the categories where someone may be in danger")
    func dangerousCategoriesStandOut() {
        let fire = CompactColumn.incidentType.cell(
            for: incident(incidentType: "Fire - Residential"),
            timeFormat: .twelveHour
        )
        let medical = CompactColumn.incidentType.cell(
            for: incident(incidentType: "MEDICAL"),
            timeFormat: .twelveHour
        )
        #expect(fire.warrantsAttention)
        #expect(!medical.warrantsAttention)
    }

    @Test("shows the alarm level as published, and marks it only when escalated")
    func alarmLevelMarksOnlyEscalation() {
        // Level 0 is an initial response and covers almost every incident, so marking it
        // would mark everything.
        let initial = CompactColumn.alarmLevel.cell(
            for: incident(alarmLevel: "0"),
            timeFormat: .twelveHour
        )
        let escalated = CompactColumn.alarmLevel.cell(
            for: incident(alarmLevel: "2"),
            timeFormat: .twelveHour
        )
        #expect(initial.text == "0")
        #expect(!initial.warrantsAttention)
        #expect(escalated.text == "2")
        #expect(escalated.warrantsAttention)
    }

    @Test("shows the apparatus roster exactly as published")
    func dispatchedUnitsArePublished() {
        // Decoding `P231` to `Pumper 231` is worth the characters in the detail view and
        // not here. The legend lives there.
        let cell = CompactColumn.dispatchedUnits.cell(
            for: incident(dispatchedUnits: "P231, P234"),
            timeFormat: .twelveHour
        )
        #expect(cell.text == "P231, P234")
        #expect(!cell.warrantsAttention)
    }

    @Test("leaves the roster empty when the feed omits the element")
    func absentRosterIsEmpty() {
        // The feed omits units_disp entirely for roughly one incident in five.
        let cell = CompactColumn.dispatchedUnits.cell(
            for: incident(dispatchedUnits: nil),
            timeFormat: .twelveHour
        )
        #expect(cell.text == nil)
    }
}
