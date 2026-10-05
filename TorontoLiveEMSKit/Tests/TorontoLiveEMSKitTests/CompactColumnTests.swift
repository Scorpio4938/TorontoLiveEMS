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
        crossStreets: String? = nil,
        dispatchTime: String = "2026-09-29T18:24:39",
        incidentType: String = "MEDICAL",
        alarmLevel: String = "0",
        dispatchedUnits: String? = "P231, P234"
    ) -> Incident {
        Incident(
            incidentNumber: "F26154815",
            primeStreet: primeStreet,
            crossStreets: crossStreets,
            dispatchTime: dispatchTime,
            incidentType: incidentType,
            alarmLevel: alarmLevel,
            area: "426",
            dispatchedUnits: dispatchedUnits
        )
    }

    @Test("is five columns, in the order they are shown")
    func columnSetAndOrder() {
        // Order is load-bearing. The header and every row iterate this same array in step, so
        // reordering it silently relabels both grids at once and still compiles. Five is this
        // source's count rather than the table's — the table draws however many it is given, and
        // the police set declares four.
        #expect(CompactColumn<Incident>.fire.map(\.id) == [
            "Prime Street",
            "Dispatch Time",
            "Incident Type",
            "Alarm Level",
            "Dispatched Units",
        ])
    }

    @Test("leaves Cross Street to the detail view")
    func crossStreetIsNotAColumn() {
        // Cross Street is in the feed and is deliberately not a column: it is blank on
        // most incidents — every medical one — and is a refinement of Prime Street
        // rather than a peer of it, so on a phone it spent width it rarely used. A test
        // rather than a comment because adding it back is a decision, not an oversight.
        let labels = CompactColumn<Incident>.fire.map { $0.label.lowercased() }
        #expect(!labels.contains { $0.contains("cross") })
    }

    @Test("names every field the way the City does")
    func everyColumnHasALabel() {
        #expect(CompactColumn<Incident>.fire.map { $0.label } == [
            "Prime Street",
            "Dispatch Time",
            "Incident Type",
            "Alarm Level",
            "Dispatched Units",
        ])
    }

    @Test("a field's own label carries no line break")
    func fieldLabelsCarryNoBreak() {
        // This is the label the stacked layout shows beside each value, where a forced
        // break would be a stray blank line rather than a column that wraps.
        for column in CompactColumn<Incident>.fire {
            #expect(!column.label.contains("\n"))
        }
    }

    @Test("breaks the header onto two lines for Alarm Level, and for nothing else")
    func headerBreaksOnlyAlarmLevel() {
        // All five headers are meant to be the same height. Alarm Level is a character
        // shorter than the next shortest label, so without a forced break it is the only
        // one that fits on a single line — which reads as a column of a different shape
        // rather than as a shorter label.
        //
        // Forcing the break is the cheap fix. Narrowing that one column was tried and
        // reverted: it moved the widths, and the alignment with them.
        for column in CompactColumn<Incident>.fire {
            #expect(column.headerLabel.contains("\n") == (column == .alarmLevel))
        }
    }

    @Test("the header label is the field label wherever there is no break to force")
    func headerLabelDefaultsToTheFieldLabel() {
        // Only Alarm Level has a reason to differ, so only Alarm Level may.
        for column in CompactColumn<Incident>.fire where column.id != CompactColumn<Incident>.alarmLevel.id {
            #expect(column.headerLabel == column.label)
        }
    }

    @Test("shows the prime street exactly as published")
    func primeStreetIsPublished() {
        let cell = CompactColumn<Incident>.primeStreet.cell(incident(), .twelveHour)
        #expect(cell.text == "QUEEN ST W")
        #expect(!cell.warrantsAttention)
    }

    @Test("falls back to the intersection when there is no prime street")
    func fallsBackToTheIntersection() {
        // The City publishes an intersection instead of an address for some incidents and
        // leaves Prime Street blank. The cell used to be empty, hiding a location the feed
        // does supply, on exactly the incidents whose location is hardest to infer.
        let intersectionOnly = incident(
            primeStreet: nil,
            crossStreets: "ARDAGH ST / JANE ST"
        )
        let cell = CompactColumn<Incident>.primeStreet.cell(intersectionOnly, .twelveHour)
        #expect(cell.text == "ARDAGH ST / JANE ST")
        #expect(cell.isFallback)
    }

    @Test("marks nothing as a fallback when the prime street is there")
    func noFallbackWhenTheAddressIsPublished() {
        let bothPublished = incident(
            primeStreet: "QUEEN ST W",
            crossStreets: "BAY ST / YORK ST"
        )
        let cell = CompactColumn<Incident>.primeStreet.cell(bothPublished, .twelveHour)
        #expect(cell.text == "QUEEN ST W")
        #expect(!cell.isFallback)
    }

    @Test("shows the mark, unmarked, when neither street is published")
    func noLocationAtAll() {
        let cell = CompactColumn<Incident>.primeStreet.cell(incident(primeStreet: nil, crossStreets: nil),
            .twelveHour
        )
        #expect(cell.text == NotProvided.mark)
        #expect(!cell.isFallback)
    }

    @Test("only the prime street column ever falls back")
    func onlyPrimeStreetFallsBack() {
        // The other four read one field each and have nothing to fall back to. If this ever
        // fails, something has started substituting values in a column that names itself
        // after one field.
        let barren = incident(
            primeStreet: nil,
            crossStreets: "ARDAGH ST / JANE ST",
            dispatchedUnits: nil
        )
        for column in CompactColumn<Incident>.fire where column.id != CompactColumn<Incident>.primeStreet.id {
            #expect(!column.cell(barren, .twelveHour).isFallback)
        }
    }

    @Test("marks an absent address rather than leaving the row without a start")
    func unpublishedPrimeStreetIsMarked() {
        // The address begins the row in both compact arrangements, so nothing at all there
        // leaves the eye with nothing to land on. It shows the same slash the detail view
        // uses — and no substitution mark, because a slash is the absence of a location
        // rather than a location found elsewhere.
        let cell = CompactColumn<Incident>.primeStreet.cell(incident(primeStreet: nil), .twelveHour)
        #expect(cell.text == NotProvided.mark)
        #expect(cell.text == "/")
        #expect(!cell.isFallback)
    }

    @Test("renders the dispatch time in the reader's chosen clock")
    func dispatchTimeFollowsTheSetting() {
        let twelve = CompactColumn<Incident>.dispatchTime.cell(incident(), .twelveHour)
        let twentyFour = CompactColumn<Incident>.dispatchTime.cell(incident(), .twentyFourHour)
        #expect(twelve.text == "6:24 PM")
        #expect(twentyFour.text == "18:24")
    }

    @Test("renders Incident Type as its category, not the published string")
    func incidentTypeIsCategorised() {
        // Width is the reason. `Vehicle - Personal Injury` is 26 characters in a column
        // that has room for about 11.
        let cell = CompactColumn<Incident>.incidentType.cell(incident(incidentType: "Vehicle - Personal Injury"),
            .twelveHour
        )
        #expect(cell.text == "Vehicle")
    }

    @Test("falls back to the published string for a type we cannot categorise")
    func unknownIncidentTypeFallsBack() {
        // Degrading to the raw value is the point: a type the City adds later shows up
        // unreadable-but-correct rather than missing.
        let cell = CompactColumn<Incident>.incidentType.cell(incident(incidentType: "Hovercraft - Inverted"),
            .twelveHour
        )
        #expect(cell.text == "Hovercraft - Inverted")
        #expect(!cell.warrantsAttention)
    }

    @Test("marks the categories where someone may be in danger")
    func dangerousCategoriesStandOut() {
        let fire = CompactColumn<Incident>.incidentType.cell(incident(incidentType: "Fire - Residential"),
            .twelveHour
        )
        let medical = CompactColumn<Incident>.incidentType.cell(incident(incidentType: "MEDICAL"), .twelveHour)
        #expect(fire.warrantsAttention)
        #expect(!medical.warrantsAttention)
    }

    @Test("shows the alarm level as published, and marks it only when the City mobilised")
    func alarmLevelMarksOnlyAMajorResponse() {
        // Level 0 is an initial response and covers almost every incident, so marking it would
        // mark everything; level 1 is one more crew. Level 2 is where the City's own meanings
        // reach ten or more vehicles.
        let initial = CompactColumn<Incident>.alarmLevel.cell(incident(alarmLevel: "0"), .twelveHour)
        let support = CompactColumn<Incident>.alarmLevel.cell(incident(alarmLevel: "1"), .twelveHour)
        let major = CompactColumn<Incident>.alarmLevel.cell(incident(alarmLevel: "2"), .twelveHour)
        #expect(initial.text == "0")
        #expect(!initial.warrantsAttention)
        #expect(support.text == "1")
        #expect(!support.warrantsAttention)
        #expect(major.text == "2")
        #expect(major.warrantsAttention)
    }

    @Test("shows the apparatus roster exactly as published")
    func dispatchedUnitsArePublished() {
        // Decoding `P231` to `Pumper 231` is worth the characters in the detail view and
        // not here. The legend lives there.
        let cell = CompactColumn<Incident>.dispatchedUnits.cell(incident(dispatchedUnits: "P231, P234"), .twelveHour)
        #expect(cell.text == "P231, P234")
        #expect(!cell.warrantsAttention)
    }

    @Test("leaves every other column empty when the feed published nothing")
    func onlyTheAddressIsMarked() {
        // The slash is for the cell that starts the row. A column of slashes is noise, and
        // an absent roster costs the reader nothing — so this is a deliberate exception
        // rather than the rule spreading.
        let barren = incident(dispatchedUnits: nil)
        #expect(CompactColumn<Incident>.dispatchedUnits.cell(barren, .twelveHour).text == nil)
    }

    @Test("leaves the roster empty when the feed omits the element")
    func absentRosterIsEmpty() {
        // The feed omits units_disp entirely for roughly one incident in five.
        let cell = CompactColumn<Incident>.dispatchedUnits.cell(incident(dispatchedUnits: nil), .twelveHour)
        #expect(cell.text == nil)
    }
}
