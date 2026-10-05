import Foundation

/// What a mark on the map is: where it came from, and what kind of thing it is.
///
/// **One type, produced by both feeds and drawn by one path.** The map used to build its own
/// fire-shaped marks, which is fine while there is one source and is exactly the shape that breaks
/// when a second arrives: two feeds drawing their own dots is two drawing processes, two sets of
/// colours, and two chances to disagree about what a thing looks like. Everything the map needs in
/// order to draw now comes from here, and the map stops knowing what a fire incident is.
///
/// **Colour is deliberately not part of a mark's identity.** A mark's colour is `warrantsAttention`'s
/// business — state, not taxonomy — and `MarkColour` holds that rule in one place. The **symbol**
/// carries the kind, so "this is a medical call" and "this one is urgent" stay two facts instead of
/// one fact made to do both jobs. `IncidentCategory`'s own note records the same decision from the
/// fire side, and this type does not reopen it.
///
/// **The filter is why `source` is here.** A reader asking for only fire incidents, or only police
/// calls, is asking a question about where a mark came from; the map can then ask each mark that one
/// question and draw the ones that answer yes.
public struct IncidentMark: Equatable, Hashable, Sendable, Identifiable {

    /// Which feed published the incident. What the map's filter works on.
    public enum Source: String, CaseIterable, Sendable, Identifiable {
        case fire
        case police

        public var id: String {
            rawValue
        }

        /// The name a reader sees in the filter.
        public var label: String {
            switch self {
            case .fire:
                return "Fire"
            case .police:
                return "Police"
            }
        }
    }

    /// What kind of incident it is, coarse enough that one symbol is worth having.
    ///
    /// **Nine, for two vocabularies of thirteen and thirty.** The City publishes sixty-nine incident
    /// types and the Service thirty call types; a symbol for each would be a legend nobody could
    /// learn, which is the thing this avoids. These are the kinds a reader actually asks about, and
    /// both feeds are projected into them — fire from its own finer `IncidentCategory`, so the
    /// sixty-nine-entry table behind that type is still what decides.
    public enum Category: String, CaseIterable, Sendable {
        case fire
        case medical
        case alarm
        case rescue
        case hazard
        case collision
        case crime
        case disturbance
        case other

        /// The SF Symbol this kind is drawn with.
        ///
        /// **Verified rather than remembered.** A name the system does not know draws *nothing* — no
        /// warning at build time, no placeholder at run time, just a gap where a mark should be — so
        /// these are asserted against the system's own catalogue in a test, not trusted.
        public var symbol: String {
            switch self {
            case .fire:
                return "flame.fill"
            case .medical:
                return "cross.case.fill"
            case .alarm:
                return "bell.fill"
            case .rescue:
                return "lifepreserver.fill"
            case .hazard:
                return "exclamationmark.triangle.fill"
            case .collision:
                return "car.fill"
            case .crime:
                return "shield.fill"
            case .disturbance:
                return "person.2.fill"
            case .other:
                return "questionmark.circle.fill"
            }
        }

        /// The name a reader would see beside the symbol, if one is ever shown.
        public var label: String {
            switch self {
            case .fire:
                return "Fire"
            case .medical:
                return "Medical"
            case .alarm:
                return "Alarm"
            case .rescue:
                return "Rescue"
            case .hazard:
                return "Hazard"
            case .collision:
                return "Collision"
            case .crime:
                return "Crime"
            case .disturbance:
                return "Disturbance"
            case .other:
                return "Other"
            }
        }

        /// The coarse kind a fire incident's own finer category belongs to.
        ///
        /// **The fine table survives; only its output is regrouped.** `IncidentCategory` maps
        /// sixty-nine published types to thirteen kinds, and that work is what decides a mark — this
        /// only says which of nine shapes thirteen kinds share. Hazard takes five of them because a
        /// reader does not act differently on a gas leak than on wires down: both mean keep away.
        ///
        /// Public because the projection is the part worth testing on its own: every one of the
        /// thirteen has to land somewhere, and a test that pinned it only through a whole `Incident`
        /// would be testing the fixture as much as the mapping.
        public init(incidentCategory: IncidentCategory) {
            switch incidentCategory {
            case .fire:
                self = .fire
            case .medical:
                self = .medical
            case .alarm:
                self = .alarm
            case .rescue:
                self = .rescue
            case .carbonMonoxide, .hazmat, .gasLeak, .water, .wiresDown:
                self = .hazard
            case .vehicle:
                self = .collision
            case .checkCall, .policeAssist, .other:
                self = .other
            }
        }
    }

    public let source: Source
    public let category: Category

    /// Whether this warrants attention, which is what the mark's colour shows.
    ///
    /// **Not derivable from `category` alone**, which is why the mark carries it: the fire feed's rule
    /// also weighs an Alarm Level, and that is a property of one response rather than of a kind of
    /// incident. `Incident.warrantsAttention` is the one home of the rule. Police calls answer `false`
    /// because the Service publishes no urgency for them — a judgement this app would otherwise be
    /// inventing.
    public let warrantsAttention: Bool

    public var id: String {
        "\(source.rawValue).\(category.rawValue)"
    }

    public init(source: Source, category: Category, warrantsAttention: Bool) {
        self.source = source
        self.category = category
        self.warrantsAttention = warrantsAttention
    }

    /// The mark for a fire incident.
    ///
    /// A type the City has never published lands in `.other` rather than being dropped: the map has to
    /// draw something, and "we do not know what this is" is a truer mark than no mark at all.
    public init(incident: Incident) {
        let category = IncidentCategory.from(incidentType: incident.incidentType)
        self.init(
            source: .fire,
            category: category.map(Category.init(incidentCategory:)) ?? .other,
            warrantsAttention: incident.warrantsAttention
        )
    }
}
