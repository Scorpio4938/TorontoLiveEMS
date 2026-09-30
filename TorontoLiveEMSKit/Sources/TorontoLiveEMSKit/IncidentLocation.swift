import Foundation

/// What the feed published about where an incident is, and how precisely.
///
/// The feed offers three different things and they are not interchangeable. An **intersection**
/// is two streets crossing, so it names a place. A **street** is a street: the City publishes
/// `LAWRENCE AVE, SC` and no number, so the best anyone can say is somewhere along it. A
/// **postal area** is not a place at all — it is a neighbourhood, published in place of an
/// address to preserve privacy — and see `docs/adr/0004-medical-locations-not-narrowed.md`.
///
/// That difference decides two things a map has to get right: what to ask a geocoder for, and
/// whether to draw a pin or an area. A pin is a claim about a point; three of these four cases
/// cannot support one.
///
/// No MapKit here. What to look up and how to represent it is data; showing it is the app's job,
/// and keeping the first half in the package is what lets it be tested.
public enum IncidentLocation: Equatable, Sendable {

    /// Two streets crossing. The most precise thing the feed publishes.
    case intersection(String)

    /// A street, with no number. Precise to somewhere along its length.
    case street(String)

    /// A forward sortation area, e.g. `M6K`. An area, never a point.
    case postalArea(String)

    /// Nothing published. Two of the eight fields are optional for this reason.
    case unpublished

    /// What to hand a geocoder, or `nil` when there is nothing to look up.
    ///
    /// The locality is part of it because the feed is Toronto-only and a bare `QUEEN ST W`
    /// geocodes confidently to the wrong continent. The City's own municipality suffixes are not
    /// part of it for the same reason: `SC` is Scarborough, which has been part of Toronto since
    /// 1998, and no geocoder wants the 1998 answer.
    public var query: String? {
        switch self {
        case .intersection(let streets):
            return "\(streets), Toronto, Ontario"
        case .street(let name):
            return "\(name), Toronto, Ontario"
        case .postalArea(let code):
            return "\(code), Toronto, Ontario"
        case .unpublished:
            return nil
        }
    }

    /// Whether this names a point or an extent.
    ///
    /// A postal area is the only extent. Drawing it as a pin would put a medical incident at the
    /// centre of a neighbourhood and call it a location, which is the narrowing the app is not
    /// allowed to do.
    public var isArea: Bool {
        if case .postalArea = self {
            return true
        }
        return false
    }

    /// What the feed published about this incident's location.
    ///
    /// **The intersection wins when there is one**, even though the app shows Prime Street as
    /// the location in its list. For reading, the street is the name of the incident's place;
    /// for looking up, two crossing streets are strictly more precise than one street name, and
    /// an addressable incident publishes both.
    public static func from(_ incident: Incident) -> IncidentLocation {
        if let intersection = incident.crossStreets, !isBlank(intersection) {
            return .intersection(intersection)
        }
        guard let street = incident.primeStreet, !isBlank(street) else {
            return .unpublished
        }
        if incident.isLocationPostalArea {
            return .postalArea(street)
        }
        return .street(strippingMunicipality(from: street))
    }

    /// The same rule the parser applies: a value with no letter and no digit in it is standing
    /// in for nothing.
    ///
    /// The parser already turns those into `nil` — a lone slash in Cross Street was doing
    /// exactly this until it was found in a live capture — so this is the second line of defence
    /// rather than the first. It is here because `Incident` is public and can be built by hand.
    private static func isBlank(_ value: String) -> Bool {
        !value.contains { $0.isLetter || $0.isNumber }
    }

    /// Removes the City's former-municipality suffix, e.g. `LAWRENCE AVE, SC` -> `LAWRENCE AVE`.
    ///
    /// The suffix is two capital letters after a comma: `TT` Toronto, `ET` Etobicoke, `NY` North
    /// York, `SC` Scarborough. Matched by shape rather than by a list, because the four above are
    /// the ones observed and a fifth would otherwise reach the geocoder as part of a street name.
    private static func strippingMunicipality(from street: String) -> String {
        let parts = street.components(separatedBy: ", ")
        guard parts.count > 1,
              let suffix = parts.last,
              suffix.count == 2,
              suffix.allSatisfy({ $0.isUppercase && $0.isLetter })
        else {
            return street
        }
        return parts.dropLast().joined(separator: ", ")
    }
}
