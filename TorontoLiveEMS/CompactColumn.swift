import Foundation
import TorontoLiveEMSKit

/// The compact table's columns, in the order they are shown.
///
/// This is the single source of truth for the column set — order, label, and the value
/// each column draws from an Incident. It is fixed at five: the table never grows
/// columns, so one layout serves every row on every device.
///
/// Cross Street is deliberately absent. It is blank on most incidents — every medical
/// one — and it is a refinement of Prime Street rather than a peer of it, so on a phone
/// it spent width it rarely used. It lives in the detail view. Incident Number and Area
/// are there too. See `docs/design-decisions.md`.
enum CompactColumn: CaseIterable {

    case primeStreet
    case dispatchTime
    case incidentType
    case alarmLevel
    case dispatchedUnits

    /// The City's own label for the field.
    var label: String {
        switch self {
        case .primeStreet:
            return "Prime Street"
        case .dispatchTime:
            return "Dispatch Time"
        case .incidentType:
            return "Incident Type"
        case .alarmLevel:
            return "Alarm Level"
        case .dispatchedUnits:
            return "Dispatched Units"
        }
    }

    /// What to show in this column for an incident.
    ///
    /// `nil` means there is nothing to show. It renders as an empty cell — no
    /// placeholder, no substitute.
    ///
    /// Anything we cannot interpret falls back to the published string.
    func text(for incident: Incident) -> String? {
        switch self {
        case .primeStreet:
            return incident.primeStreet
        case .dispatchTime:
            return DispatchTimestamp.clockTime(incident.dispatchTime)
        case .incidentType:
            return IncidentCategory.from(incidentType: incident.incidentType)?.label
                ?? incident.incidentType
        case .alarmLevel:
            return incident.alarmLevel
        case .dispatchedUnits:
            // Left exactly as published. Decoding `P231` to `Pumper 231` is worth the
            // characters in the detail view and not here, where width is the scarcest
            // thing we have.
            return incident.dispatchedUnits
        }
    }
}
