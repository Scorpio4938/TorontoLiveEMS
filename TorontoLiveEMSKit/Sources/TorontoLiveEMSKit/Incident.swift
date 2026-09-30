/// One active incident, as published by Toronto Fire Services CAD.
///
/// Every field the feed publishes is retained, unreduced, so display decisions can
/// change without re-fetching. See `docs/adr/0002-raw-payload-retained-in-memory.md`.
///
/// Five of the eight fields are always populated. Three are observed blank or absent
/// and are therefore optional; all three mean the same thing, "not published".
public struct Incident: Identifiable, Equatable, Sendable {

    /// CAD's identifier for the incident, stable across refreshes.
    ///
    /// This is the incident's identity — the only thing that lets one incident be
    /// recognised across two polls. It is an ordinal, rising with dispatch order; it
    /// says nothing about severity.
    public var id: String { incidentNumber }

    /// The stable identifier CAD assigns, e.g. `F26154815`.
    public let incidentNumber: String

    /// A street name for addressable incidents, an FSA for medical incidents.
    ///
    /// `nil` on incidents whose only published location is an intersection — the feed
    /// sends an XML-escaped space (`&#x20;`) in that case.
    public let primeStreet: String?

    /// The two intersecting streets bounding the location, e.g.
    /// `WOODBINE AVE / KINGSTON RD`. `nil` when absent or empty, which is the case
    /// for every medical incident.
    public let crossStreets: String?

    /// The raw dispatch timestamp exactly as published, e.g. `2026-09-29T18:24:39`.
    public let dispatchTime: String

    /// CAD's own category string, e.g. `MEDICAL` or `Vehicle - Personal Injury`.
    ///
    /// Not to be confused with Incident Category, which is ours and derived from this.
    public let incidentType: String

    /// The response-escalation ordinal, as published, e.g. `0`.
    public let alarmLevel: String

    /// The nearest fire station, as a bare station number, e.g. `426`.
    public let area: String

    /// Apparatus dispatched, as published codes, e.g. `P231, P234`. `nil` when the
    /// feed omits the element entirely, which it does for roughly one incident in five.
    public let dispatchedUnits: String?

    public init(
        incidentNumber: String,
        primeStreet: String?,
        crossStreets: String?,
        dispatchTime: String,
        incidentType: String,
        alarmLevel: String,
        area: String,
        dispatchedUnits: String?
    ) {
        self.incidentNumber = incidentNumber
        self.primeStreet = primeStreet
        self.crossStreets = crossStreets
        self.dispatchTime = dispatchTime
        self.incidentType = incidentType
        self.alarmLevel = alarmLevel
        self.area = area
        self.dispatchedUnits = dispatchedUnits
    }
}

public extension Incident {

    /// Whether this incident is one the colour rule marks.
    ///
    /// A dangerous category, or an alarm level above the initial response. The rule has been
    /// stated in two places since it was written — once on Incident Type and once on Alarm Level,
    /// because they are separate columns — and the map made it a third. It is one rule about an
    /// incident, so it lives on the incident.
    ///
    /// See `docs/design-grammar.md`: colour marks state rather than taxonomy, and the states are
    /// these two.
    var warrantsAttention: Bool {
        (IncidentCategory.from(incidentType: incidentType)?.warrantsAttention ?? false)
            || AlarmLevel.isEscalated(alarmLevel)
    }

    /// Whether Prime Street is a forward sortation area rather than a street name.
    ///
    /// The City publishes a medical incident's location that way — `M6G` instead of an
    /// address — to preserve privacy, and it is the reason such an incident has no
    /// mappable point. See `docs/adr/0004-medical-locations-not-narrowed.md`.
    var isLocationPostalArea: Bool {
        guard let primeStreet else {
            return false
        }
        let characters = Array(primeStreet)
        guard characters.count == 3 else {
            return false
        }
        return characters[0].isLetter
            && characters[1].isWholeNumber
            && characters[2].isLetter
    }
}
