import Foundation

/// What a mark on the map is: where it came from, and what kind of thing it is.
///
/// **One type, produced by both feeds and drawn by one path.** The map used to build its own
/// fire-shaped marks, which is fine while there is one source and is exactly the shape that breaks
/// when a second arrives: two feeds drawing their own dots is two drawing processes, two sets of
/// colours, and two chances to disagree about what a thing looks like. Everything the map needs in
/// order to draw now comes from here, and the map stops knowing what a fire incident is.
///
/// **Colour is deliberately not part of a mark's identity.** A mark's colour is `urgency`'s
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
        case traffic
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
            case .traffic:
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
            case .traffic:
                return "Traffic"
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
                self = .traffic
            case .checkCall, .policeAssist, .other:
                self = .other
            }
        }

        /// The coarse kind a police call belongs to, from the Service's own code.
        ///
        /// **A table rather than a rule, because the codes cannot be read.** `INDEX` means *indecent
        /// exposure* while `EXPJU` means *indecent exposure just occurred*, so the letters are not an
        /// abbreviation scheme and no amount of parsing would recover the meaning. Every one of the
        /// thirty codes the app knows is listed, and the mapping from a code to a kind is this app's
        /// judgement about where it belongs — not the Service's, which publishes no kinds at all.
        ///
        /// **`nil` means "no mapping", and that is different from `.other`.** A code the Service has
        /// started using since this list was gathered is genuinely unknown, and it has to be
        /// distinguishable from `FOUND PROPERTY` and `UNKNOWN TROUBLE`, which really do belong in
        /// `.other`. A test walks `PoliceCallType.documented` and fails if any code in the app's own
        /// list has no mapping, so adding a code forces the question.
        public static func from(callTypeCode: String) -> Category? {
            switch callTypeCode {
            case "FIR":
                return .fire
            case "FIRAL":
                return .alarm
            case "SEEAM":
                return .medical
            case "JUVLO", "MISCH", "MISEL", "MISVU":
                return .rescue
            case "HAZ":
                return .hazard
            case "IMPDR", "PDACC", "PIACC", "TRAOB", "WRWAY":
                return .traffic
            case "ARR", "ASS", "ASSJU", "ASSPR", "ATTBR", "BREEN", "BREJU", "BREPR", "DAM",
                 "DAMPR", "EXPJU", "FRA", "FRAPR", "INDEX", "PERGU", "PERKN", "ROB", "THE",
                 "THEAU", "THEJU", "THEPR", "THEVE", "TRE":
                return .crime
            case "DEMO", "DIS", "DISPU", "FIG":
                return .disturbance
            // `UNKNOWN TROUBLE` is `.other` and not `.disturbance`: the Service's own word is that it
            // does not know, and answering a question the Service left open would be inventing one.
            case "FOUPR", "UNKTR":
                return .other
            default:
                return nil
            }
        }
    }

    public let source: Source
    public let category: Category

    /// How much this incident matters, which is what the mark's colour shows.
    ///
    /// The **symbol** carries the kind; this carries the weight. Keeping them apart is the rule the
    /// fire side already recorded — colour marks state, not taxonomy — and the reason the two live in
    /// different properties.
    public let urgency: Urgency

    public var id: String {
        "\(source.rawValue).\(category.rawValue)"
    }

    public init(source: Source, category: Category, urgency: Urgency) {
        self.source = source
        self.category = category
        self.urgency = urgency
    }

    /// How much an incident matters.
    ///
    /// **Four steps, three tones.** `routine` and `unknown` are different claims — "this is ordinary"
    /// and "nobody has said how serious this is" — and they are drawn the same colour, because the
    /// map's job is to say what is alarming and neither of them is. What tells them apart is the
    /// symbol, which is where a kind belongs.
    public enum Urgency: String, CaseIterable, Sendable {
        case critical
        case elevated
        case routine
        case unknown

        /// Where a severity sits in the order, for choosing between two records at one place.
        ///
        /// `critical` first, `unknown` after `routine` — which is not a claim that an unnamed call is
        /// the least serious. It is that where two records share a place, one that says something beats
        /// one that says nothing.
        public var rank: Int {
            switch self {
            case .critical: return 0
            case .elevated: return 1
            case .routine: return 2
            case .unknown: return 3
            }
        }

        /// The severity of a fire incident, from the two halves of the rule the app already had.
        ///
        /// **Nothing new is judged here.** `Incident.warrantsAttention` is a dangerous *category* or a
        /// *major response*, and those are two different amounts of attention — which is exactly what
        /// collapsing them into one yes-or-no hid. A fire is critical; ten vehicles sent to a medical
        /// call is elevated; the rest is routine.
        public init(incident: Incident) {
            if IncidentCategory.from(incidentType: incident.incidentType)?.warrantsAttention == true {
                self = .critical
            } else if AlarmLevel.isMajorResponse(incident.alarmLevel) {
                self = .elevated
            } else {
                self = .routine
            }
        }

        /// The severity of a police call, inferred from the Service's own code.
        ///
        /// **Inferred, and this app is the one inferring it.** The Service publishes no severity and
        /// nothing in a call says how serious it is. An earlier version of this file refused the
        /// judgement altogether and left every police mark neutral; that was honest and useless, because
        /// an assault and a found bicycle then looked identical. What replaced it is an inference from
        /// the same kind of judgement the categories already come from, written down here where it can
        /// be argued with — which is the whole of the mitigation available.
        ///
        /// `UNKTR` is `.unknown` because the Service's own word for it is that it does not know, and so
        /// is any code this table has not met, because then it is this app that does not.
        ///
        /// **The rule the entries follow, stated so it can be disagreed with**: something *in progress*
        /// or *just occurred*, or a weapon in somebody's hand, is at least elevated and often critical;
        /// a plain report of something that has already happened is elevated or routine. It is applied
        /// by hand, one code at a time — the entries are a table rather than a rule because the codes
        /// are not compositional, and `ROB` sitting beside `PERKN` is a decision rather than a parsing.
        public init(callTypeCode code: String) {
            switch code {
            case "PERGU", "PERKN", "ASSPR", "ASSJU", "FIR", "HAZ", "MISCH", "WRWAY":
                // A person with a gun, an assault in progress, a fire, a hazard, a car driving the
                // wrong way up a road: the ones where somebody may be in danger as the call arrives.
                self = .critical
            case "ASS", "ATTBR", "BREEN", "BREJU", "BREPR", "DAMPR", "EXPJU", "FIG", "FRAPR",
                 "IMPDR", "INDEX", "MISEL", "MISVU", "PIACC", "ROB", "SEEAM", "THEJU", "THEPR":
                // Serious, and already happened, or happening to property rather than to a person.
                self = .elevated
            case "ARR", "DAM", "DEMO", "DIS", "DISPU", "FIRAL", "FOUPR", "FRA", "JUVLO", "PDACC",
                 "THE", "THEAU", "THEVE", "TRAOB", "TRE":
                self = .routine
            case "UNKTR":
                self = .unknown
            default:
                // A code the app has never seen. `.unknown` rather than `.routine`, because "we do not
                // know this one" is not the same claim as "this one is ordinary".
                self = .unknown
            }
        }
    }

    /// The mark for a police call.
    ///
    /// The severity is inferred from the code, which is the one judgement in this file that is not the
    /// Service's. See `Urgency.init(callTypeCode:)` for what it infers and why.
    public init(call: PoliceCall) {
        self.init(
            source: .police,
            category: Category.from(callTypeCode: call.callTypeCode) ?? .other,
            urgency: Urgency(callTypeCode: call.callTypeCode)
        )
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
            urgency: Urgency(incident: incident)
        )
    }
}
