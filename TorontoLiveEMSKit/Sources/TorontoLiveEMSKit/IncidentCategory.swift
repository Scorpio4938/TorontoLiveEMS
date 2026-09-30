import Foundation

/// A coarse label for what kind of incident this is.
///
/// Derived from the CAD code the City assigns. The live feed publishes Incident Type
/// with that code stripped — `FIR - Fire - Residential` arrives as
/// `Fire - Residential` — so the table below is keyed by the stripped display string,
/// rebuilt from the City's own Open Data vocabulary for all 69 published types.
/// See `docs/adr/0003-incident-category-from-cad-prefix.md`.
///
/// Alarm is deliberately separate from Fire. The City's codes separate `FA*` from
/// `FI*`; merging them would label roughly a fifth of all incidents `Fire` when the
/// Open Data `Final_Incident_Type` shows those are overwhelmingly benign.
public enum IncidentCategory: String, CaseIterable, Sendable {

    case medical
    case fire
    case alarm
    case vehicle
    case rescue
    case carbonMonoxide
    case hazmat
    case gasLeak
    case water
    case wiresDown
    case checkCall
    case policeAssist
    case other

    /// Shown in place of the full Incident Type.
    public var label: String {
        switch self {
        case .medical:
            return "Medical"
        case .fire:
            return "Fire"
        case .alarm:
            return "Alarm"
        case .vehicle:
            return "Vehicle"
        case .rescue:
            return "Rescue"
        case .carbonMonoxide:
            return "Carbon Monoxide"
        case .hazmat:
            return "Hazmat"
        case .gasLeak:
            return "Gas Leak"
        case .water:
            return "Water"
        case .wiresDown:
            return "Wires Down"
        case .checkCall:
            return "Check Call"
        case .policeAssist:
            return "Police Assist"
        case .other:
            return "Other"
        }
    }

    /// The category for a published Incident Type.
    ///
    /// Returns `nil` for a type the City has never published, so that the caller can
    /// fall back to the raw string rather than mislabel it.
    public static func from(incidentType: String) -> IncidentCategory? {
        return lookup[normalize(incidentType)]
    }

    /// Case- and whitespace-insensitive, because the feed is inconsistent with itself:
    /// it sends `MEDICAL` in capitals where the City's vocabulary says `Medical`, and
    /// at least one type carries a doubled space.
    private static func normalize(_ incidentType: String) -> String {
        return incidentType
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .lowercased()
    }

    private static let lookup: [String: IncidentCategory] = [
        // Medical - 1 published types
        "medical":                                     .medical,   // no CAD code

        // Fire - 16 published types
        "fire - highrise residential":                 .fire,   // was FIHR
        "fire - commercial/industrial":                .fire,   // was FICI
        "fire - encampment":                           .fire,   // was FIG2
        "fire - grass/rubbish":                        .fire,   // was FIG
        "fire - highrise commercial":                  .fire,   // was FIHC
        "fire - hydro vault":                          .fire,   // was FIHV
        "fire - institution":                          .fire,   // was FII
        "fire - institution - school":                 .fire,   // was FIIS
        "fire - other":                                .fire,   // was FIO
        "fire - outside storage":                      .fire,   // was FIOS
        "fire - residential":                          .fire,   // was FIR
        "fire - subway":                               .fire,   // was FIS
        "fire - transformer/pole":                     .fire,   // was FITP
        "fire - underground":                          .fire,   // was FIU
        "fire waterfront marina/industrial":           .fire,   // was FIWMI
        "lake fire response":                          .fire,   // was LKFI

        // Alarm - 11 published types
        "alarm - institution - school":                .alarm,   // was FAIS
        "alarm commercial/industrial":                 .alarm,   // was FACI
        "alarm highrise commercial":                   .alarm,   // was FAHC
        "alarm highrise residential":                  .alarm,   // was FAHR
        "alarm institution":                           .alarm,   // was FAI
        "alarm residential":                           .alarm,   // was FAR
        "alarm single source":                         .alarm,   // was FASS
        "alarm subway":                                .alarm,   // was FAS
        "alarm waterfront marina/industrial":          .alarm,   // was FAWMI
        "fire alarm - check call":                     .alarm,   // was FACC
        "island fire alarm response":                  .alarm,   // was ISFA

        // Vehicle - 11 published types
        "vehicle - personal injury":                   .vehicle,   // was VEPI
        "vehicle - personal injury highway":           .vehicle,   // was VEPIH
        "vehicle - spill clean up":                    .vehicle,   // was VESC
        "vehicle - spill clean up - highway":          .vehicle,   // was VESCH
        "vehicle - spill clean up - non emergency":    .vehicle,   // was VESCNE
        "vehicle accident - minor fuel leak":          .vehicle,   // was VEALF
        "vehicle accident - trapped":                  .vehicle,   // was VEAT
        "vehicle accident - trapped - highway":        .vehicle,   // was VEATH
        "vehicle accident with fire":                  .vehicle,   // was VEAF
        "vehicle fire":                                .vehicle,   // was VEF
        "vehicle fire - highway":                      .vehicle,   // was VEFH

        // Rescue - 14 published types
        "lake rescue response":                        .rescue,   // was LKRE
        "rescue - bluffs":                             .rescue,   // was REB
        "rescue - confined space":                     .rescue,   // was RECS
        "rescue - elevator":                           .rescue,   // was REE
        "rescue - high level":                         .rescue,   // was REHL
        "rescue - industrial":                         .rescue,   // was REI
        "rescue - other":                              .rescue,   // was REO
        "rescue - personal entrapment":                .rescue,   // was REPE
        "rescue - structural collapse":                .rescue,   // was REST
        "rescue - subway":                             .rescue,   // was RES
        "rescue - water pool":                         .rescue,   // was REWP
        "rescue - water w/fireboat":                   .rescue,   // was REWL
        "rescue - water/ice - no fireboat":            .rescue,   // was REWR
        "rescue major transportation":                 .rescue,   // was REMT

        // Carbon Monoxide - 2 published types
        "carbon monoxide - non medical":               .carbonMonoxide,   // was CONM
        "carbon monoxide - non medical - non emergency": .carbonMonoxide,   // was CONMNE

        // Hazmat - 3 published types
        "clandestine lab":                             .hazmat,   // was CLAN
        "hazmat level 1":                              .hazmat,   // was HAZ1
        "hazmat level 2":                              .hazmat,   // was HAZ2

        // Gas Leak - 2 published types
        "natural gas fire":                            .gasLeak,   // was NGASFI
        "natural gas leak":                            .gasLeak,   // was NGASLK

        // Water - 2 published types
        "water problem - level 1":                     .water,   // was WAT1
        "water problem - level 2":                     .water,   // was WAT2

        // Wires Down - 1 published types
        "wires down - hydro":                          .wiresDown,   // was WDH

        // Check Call - 2 published types
        "check call":                                  .checkCall,   // was CC
        "check call - non emergency":                  .checkCall,   // was CCNE

        // Police Assist - 2 published types
        "police assist - bomb":                        .policeAssist,   // was PABOMB
        "police assist - request":                     .policeAssist,   // was PA

        // Other - 2 published types
        "cbrn level 1":                                .other,   // was CBRN1
        "public hazard":                               .other,   // was PUB
    ]
}
