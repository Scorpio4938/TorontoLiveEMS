import Foundation

/// One cell of the compact table: what to show, and whether it should stand out.
///
/// Almost every cell is neutral. Colour marks state rather than taxonomy — a fire, a
/// hazmat call, an escalated alarm level — because colouring all thirteen categories
/// equally would make the sixty-four percent of incidents that are medical as loud as
/// the five percent that are fires. See `docs/design-decisions.md`.
public struct CompactCell: Equatable, Sendable {

    public let text: String?
    public let warrantsAttention: Bool

    /// Whether this value came from a field other than the one the column names.
    ///
    /// There is one case. The City publishes an intersection instead of an address for some
    /// incidents, and leaves Prime Street blank when it does — the intersection is not a
    /// refinement of a missing address there, it is the only location there is. So it stands
    /// in, and is marked, because a reader who sees two street names joined by a slash in a
    /// column that otherwise holds one address should be able to find out why.
    ///
    /// A flag rather than a mark baked into `text`, so the published value stays exactly as
    /// published and the view decides how to say the rest.
    public let isFallback: Bool

    /// A blank value is not a value, and a mark with nothing to mark is a contradiction.
    /// Both are settled here rather than at each call site, so the state cannot be built even
    /// by a caller that tries — a cell that showed the intersection mark over an empty
    /// address is exactly what this prevents, and it is not a thing any caller should have to
    /// remember not to do.
    ///
    /// The blank check mirrors the parser's, which already turns the feed's three
    /// "not published" shapes into `nil`. This is the second line of defence rather than the
    /// first, and it is here because the first one is in another module.
    public init(
        _ text: String?,
        warrantsAttention: Bool = false,
        isFallback: Bool = false
    ) {
        let isBlank = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.text = isBlank ? nil : text
        self.warrantsAttention = warrantsAttention
        self.isFallback = isFallback && !isBlank
    }
}

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
///
/// Lives in the package rather than the app target because it is content, not layout:
/// it maps an Incident to strings and flags, and imports nothing from SwiftUI. That is
/// what lets the mapping be tested. The measurements that lay these columns out are
/// `CompactTable`, in the app target.
public enum CompactColumn: CaseIterable, Sendable {

    case primeStreet
    case dispatchTime
    case incidentType
    case alarmLevel
    case dispatchedUnits

    /// The City's own label for the field, with no line break in it.
    ///
    /// This is the label the stacked layout shows beside each value, where a forced break
    /// would be a stray blank line rather than a column that wraps.
    public var label: String {
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

    /// The label as the column header shows it.
    ///
    /// Only `Alarm Level` differs. It is a character shorter than the next shortest
    /// label, so it was the only header that fitted on one line while the other four
    /// wrapped to two — which reads as a column of a different shape rather than as a
    /// shorter label. The break is forced so all five match.
    ///
    /// Forcing it is the cheap fix. Narrowing that one column was tried and reverted: it
    /// moved the widths, and the alignment with them.
    public var headerLabel: String {
        switch self {
        case .alarmLevel:
            return "Alarm\nLevel"
        default:
            return label
        }
    }

    /// What to show in this column for an incident, and whether it should stand out.
    ///
    /// `nil` text means there is nothing to show. It renders as an empty cell — no
    /// placeholder, no substitute.
    ///
    /// Anything we cannot interpret falls back to the published string.
    public func cell(for incident: Incident, timeFormat: DispatchTimeFormat) -> CompactCell {
        switch self {
        case .primeStreet:
            // Normally the address, or the postal area the City publishes in its place for a
            // medical incident. Both are `primeStreet`, and both are shown as published.
            if let street = incident.primeStreet {
                return CompactCell(street)
            }

            // Prime Street is blank here, which means the City published an intersection and
            // nothing else. Leaving the cell empty would hide a location the feed supplies,
            // for the incidents whose location is hardest to guess — so the intersection
            // stands in, marked as the fallback it is.
            //
            // Cross Street stays out of the table otherwise: it is a refinement of Prime
            // Street rather than a peer of it, and it is blank on most incidents. See
            // `docs/design-decisions.md`.
            // Neither street, which happens: the counter is the only place a location was
            // published, or nothing was. An empty cell, and no mark on it. Asking
            // `CompactCell` for a marked blank would be asking for a contradiction, and it
            // answers with a plain blank.
            guard let intersection = incident.crossStreets,
                  !intersection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return CompactCell(nil)
            }
            return CompactCell(intersection, isFallback: true)

        case .dispatchTime:
            return CompactCell(
                DispatchTimestamp.clockTime(incident.dispatchTime, format: timeFormat)
            )

        case .incidentType:
            let category = IncidentCategory.from(incidentType: incident.incidentType)
            return CompactCell(
                category?.label ?? incident.incidentType,
                warrantsAttention: category?.warrantsAttention ?? false
            )

        case .alarmLevel:
            return CompactCell(
                incident.alarmLevel,
                warrantsAttention: AlarmLevel.isEscalated(incident.alarmLevel)
            )

        case .dispatchedUnits:
            // Left exactly as published. Decoding `P231` to `Pumper 231` is worth the
            // characters in the detail view and not here, where width is the scarcest
            // thing we have.
            return CompactCell(incident.dispatchedUnits)
        }
    }
}
