import Testing
import TorontoLiveEMSKit

@Suite("Incident categories")
struct IncidentCategoryTests {

    @Test("maps each of the City's incident families to a category")
    func mapsPublishedFamilies() {
        #expect(IncidentCategory.from(incidentType: "Fire - Residential") == .fire)
        #expect(IncidentCategory.from(incidentType: "Alarm Single Source") == .alarm)
        #expect(IncidentCategory.from(incidentType: "Vehicle - Personal Injury") == .vehicle)
        #expect(IncidentCategory.from(incidentType: "Rescue - Elevator") == .rescue)
        #expect(IncidentCategory.from(incidentType: "Medical") == .medical)
        #expect(IncidentCategory.from(incidentType: "Carbon Monoxide - Non Medical") == .carbonMonoxide)
        #expect(IncidentCategory.from(incidentType: "Hazmat Level 1") == .hazmat)
        #expect(IncidentCategory.from(incidentType: "Natural Gas Leak") == .gasLeak)
        #expect(IncidentCategory.from(incidentType: "Water Problem - Level 1") == .water)
        #expect(IncidentCategory.from(incidentType: "Wires Down - Hydro") == .wiresDown)
        #expect(IncidentCategory.from(incidentType: "Check Call") == .checkCall)
        #expect(IncidentCategory.from(incidentType: "Police Assist - Request") == .policeAssist)
        #expect(IncidentCategory.from(incidentType: "Public Hazard") == .other)
    }

    @Test("keeps Alarm separate from Fire")
    func alarmIsNotFire() {
        // The City's codes separate FA* from FI*. Folding them together would label
        // roughly a fifth of all incidents as a fire.
        #expect(IncidentCategory.from(incidentType: "Alarm Single Source") == .alarm)
        #expect(IncidentCategory.from(incidentType: "Alarm Highrise Residential") == .alarm)
        #expect(IncidentCategory.from(incidentType: "Fire Alarm - Check Call") == .alarm)
        #expect(IncidentCategory.from(incidentType: "Fire - Residential") == .fire)
    }

    @Test("categorises the types a code prefix alone would get wrong")
    func handlesPrefixExceptions() {
        // Every one of these has a prefix that would sort it into the wrong family.
        #expect(IncidentCategory.from(incidentType: "Lake Fire Response") == .fire)
        #expect(IncidentCategory.from(incidentType: "Lake Rescue Response") == .rescue)
        #expect(IncidentCategory.from(incidentType: "Island Fire Alarm Response") == .alarm)
        #expect(IncidentCategory.from(incidentType: "Clandestine Lab") == .hazmat)
        #expect(IncidentCategory.from(incidentType: "CBRN Level 1") == .other)
    }

    @Test("tolerates the feed's inconsistent capitalisation")
    func toleratesCapitalisation() {
        // The feed sends this one in capitals; the City's vocabulary says "Medical".
        #expect(IncidentCategory.from(incidentType: "MEDICAL") == .medical)
        #expect(IncidentCategory.from(incidentType: "medical") == .medical)
    }

    @Test("tolerates a doubled space inside a published type")
    func toleratesDoubledSpace() {
        #expect(IncidentCategory.from(incidentType: "Fire -  Highrise Residential") == .fire)
    }

    @Test("has no category for a type the City has never published")
    func unknownTypeHasNoCategory() {
        // The caller falls back to the raw string; the point is that we do not guess.
        #expect(IncidentCategory.from(incidentType: "Hovercraft - Inverted") == nil)
    }

    @Test("every category can name itself")
    func everyCategoryHasALabel() {
        for category in IncidentCategory.allCases {
            #expect(!category.label.isEmpty)
        }
    }

    @Test("marks only the categories where someone may be in danger")
    func onlyDangerousCategoriesStandOut() {
        #expect(IncidentCategory.fire.warrantsAttention)
        #expect(IncidentCategory.hazmat.warrantsAttention)
        #expect(IncidentCategory.carbonMonoxide.warrantsAttention)
        #expect(IncidentCategory.rescue.warrantsAttention)

        // The majority stay neutral. Marking them would make the 64% of incidents that
        // are medical as loud as the 5% that are fires, which is the opposite of the job.
        #expect(!IncidentCategory.medical.warrantsAttention)
        #expect(!IncidentCategory.alarm.warrantsAttention)
        #expect(!IncidentCategory.vehicle.warrantsAttention)
        #expect(!IncidentCategory.gasLeak.warrantsAttention)
        #expect(!IncidentCategory.water.warrantsAttention)
        #expect(!IncidentCategory.wiresDown.warrantsAttention)
        #expect(!IncidentCategory.checkCall.warrantsAttention)
        #expect(!IncidentCategory.policeAssist.warrantsAttention)
        #expect(!IncidentCategory.other.warrantsAttention)
    }

    @Test("marks a small minority of the categories")
    func marksAMinority() {
        // Colour is for exceptions. If this ever creeps up, the tint has stopped marking
        // anything and become decoration.
        let marked = IncidentCategory.allCases.filter(\.warrantsAttention)
        #expect(marked.count == 4)
    }
}
