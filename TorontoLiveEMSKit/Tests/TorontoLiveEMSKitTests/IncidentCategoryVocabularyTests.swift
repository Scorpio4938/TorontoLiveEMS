import Testing
import TorontoLiveEMSKit

/// Every Incident Type the City has published, paired with the category it must map to.
///
/// Generated from the City's Open Data `Initial_CAD_Event_Type` vocabulary with the CAD
/// code prefix stripped, so these strings are exactly what the live feed emits —
/// including the doubled space in one of them and the two that carry no ` - ` separator,
/// because the City's own vocabulary is inconsistent that way.
///
/// A test over a sample would not catch a single mistyped lookup key. This covers all
/// 69.
@Suite("Incident categories: the full published vocabulary")
struct IncidentCategoryVocabularyTests {

    struct PublishedType: Sendable {
        let type: String
        let category: IncidentCategory

        init(_ type: String, _ category: IncidentCategory) {
            self.type = type
            self.category = category
        }
    }

    @Test("categorises every one of the City's published incident types")
    func categorisesEveryPublishedType() {
        for published in Self.types {
            let actual = IncidentCategory.from(incidentType: published.type)
            #expect(actual == published.category, "\(published.type) should be \(published.category)")
        }
    }

    static let types: [PublishedType] = [
        PublishedType("Alarm - Institution - School", .alarm),
        PublishedType("Alarm Commercial/Industrial", .alarm),
        PublishedType("Alarm Highrise Commercial", .alarm),
        PublishedType("Alarm Highrise Residential", .alarm),
        PublishedType("Alarm Institution", .alarm),
        PublishedType("Alarm Residential", .alarm),
        PublishedType("Alarm Single Source", .alarm),
        PublishedType("Alarm Subway", .alarm),
        PublishedType("Alarm Waterfront Marina/Industrial", .alarm),
        PublishedType("Fire Alarm - Check Call", .alarm),
        PublishedType("Island Fire Alarm Response", .alarm),
        PublishedType("Carbon Monoxide - Non Medical", .carbonMonoxide),
        PublishedType("Carbon Monoxide - Non Medical - Non Emergency", .carbonMonoxide),
        PublishedType("Check Call", .checkCall),
        PublishedType("Check Call - Non Emergency", .checkCall),
        PublishedType("Fire -  Highrise Residential", .fire),
        PublishedType("Fire - Commercial/Industrial", .fire),
        PublishedType("Fire - Encampment", .fire),
        PublishedType("Fire - Grass/Rubbish", .fire),
        PublishedType("Fire - Highrise Commercial", .fire),
        PublishedType("Fire - Hydro Vault", .fire),
        PublishedType("Fire - Institution", .fire),
        PublishedType("Fire - Institution - School", .fire),
        PublishedType("Fire - Other", .fire),
        PublishedType("Fire - Outside Storage", .fire),
        PublishedType("Fire - Residential", .fire),
        PublishedType("Fire - Subway", .fire),
        PublishedType("Fire - Transformer/Pole", .fire),
        PublishedType("Fire - Underground", .fire),
        PublishedType("Fire Waterfront Marina/Industrial", .fire),
        PublishedType("Lake Fire Response", .fire),
        PublishedType("Natural Gas Fire", .gasLeak),
        PublishedType("Natural Gas Leak", .gasLeak),
        PublishedType("Clandestine Lab", .hazmat),
        PublishedType("Hazmat Level 1", .hazmat),
        PublishedType("Hazmat Level 2", .hazmat),
        PublishedType("Medical", .medical),
        PublishedType("CBRN Level 1", .other),
        PublishedType("Public Hazard", .other),
        PublishedType("Police Assist - Bomb", .policeAssist),
        PublishedType("Police Assist - Request", .policeAssist),
        PublishedType("Lake Rescue Response", .rescue),
        PublishedType("Rescue - Bluffs", .rescue),
        PublishedType("Rescue - Confined Space", .rescue),
        PublishedType("Rescue - Elevator", .rescue),
        PublishedType("Rescue - High Level", .rescue),
        PublishedType("Rescue - Industrial", .rescue),
        PublishedType("Rescue - Other", .rescue),
        PublishedType("Rescue - Personal Entrapment", .rescue),
        PublishedType("Rescue - Structural Collapse", .rescue),
        PublishedType("Rescue - Subway", .rescue),
        PublishedType("Rescue - Water Pool", .rescue),
        PublishedType("Rescue - Water w/Fireboat", .rescue),
        PublishedType("Rescue - Water/Ice - No Fireboat", .rescue),
        PublishedType("Rescue Major Transportation", .rescue),
        PublishedType("Vehicle - Personal Injury", .vehicle),
        PublishedType("Vehicle - Personal Injury Highway", .vehicle),
        PublishedType("Vehicle - Spill Clean Up", .vehicle),
        PublishedType("Vehicle - Spill Clean Up - Highway", .vehicle),
        PublishedType("Vehicle - Spill Clean Up - Non Emergency", .vehicle),
        PublishedType("Vehicle Accident - Minor Fuel Leak", .vehicle),
        PublishedType("Vehicle Accident - Trapped", .vehicle),
        PublishedType("Vehicle Accident - Trapped - Highway", .vehicle),
        PublishedType("Vehicle Accident with Fire", .vehicle),
        PublishedType("Vehicle Fire", .vehicle),
        PublishedType("Vehicle Fire - Highway", .vehicle),
        PublishedType("Water Problem - Level 1", .water),
        PublishedType("Water Problem - Level 2", .water),
        PublishedType("Wires Down - Hydro", .wiresDown),
    ]
}
