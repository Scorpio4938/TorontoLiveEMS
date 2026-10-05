import Foundation

/// Reads the calls out of the service's own JSON.
///
/// **Esri's JSON, not GeoJSON.** Both are on offer and this reads the one that keeps numbers as
/// numbers: Esri's GeoJSON output *stringifies* every attribute, so `OCCURRENCE_TIME` arrives as
/// `"1791219259000"`, while its own format sends `1791219259000`. Nothing here needs the geometry —
/// the point is published as two attributes — so the typed response is less code rather than more.
///
/// The shape is `{"features":[{"attributes":{…}}]}`. The service declares its own schema, so a field
/// that changes type is a decode failure rather than a wrong value, and a half-read list is refused
/// rather than returned: the same judgement `PostalAreas` makes about its own file.
public enum CallsForServiceParserError: Error, Equatable {
    /// The response was not the shape this reads. Carries what the decoder said, because "the
    /// service changed something" and "the network returned a login page" are worth telling apart.
    case notTheService(said: String)
}

public enum CallsForServiceParser {

    /// The calls in a response, in the order the service returned them.
    public static func parse(_ data: Data) throws -> [PoliceCall] {
        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw CallsForServiceParserError.notTheService(said: String(describing: error))
        }
        return response.features.map(\.call)
    }

    private struct Response: Decodable {
        let features: [Feature]
    }

    private struct Feature: Decodable {
        let attributes: Attributes

        var call: PoliceCall {
            PoliceCall(
                objectID: attributes.OBJECTID,
                // Milliseconds since 1970, as published.
                occurrenceTime: Date(timeIntervalSince1970: attributes.OCCURRENCE_TIME / 1000),
                division: attributes.DIVISION,
                latitude: attributes.LATITUDE,
                longitude: attributes.LONGITUDE,
                callTypeCode: attributes.CALL_TYPE_CODE,
                callType: attributes.CALL_TYPE,
                crossStreets: published(attributes.CROSS_STREETS)
            )
        }

        struct Attributes: Decodable {
            let OBJECTID: Int
            let OCCURRENCE_TIME: Double
            let DIVISION: String
            let LATITUDE: Double
            let LONGITUDE: Double
            let CALL_TYPE_CODE: String
            let CALL_TYPE: String
            let CROSS_STREETS: String?
        }

        /// A value that is standing in for nothing comes back as nothing.
        ///
        /// **The same rule the fire parser applies, stated a third time and for the same reason.**
        /// The two feeds each have their own shapes for "not published" — an empty element, an
        /// absent one, an escaped space, a bare separator — and they all come to the same thing: **no
        /// letter and no digit means no value.** The parsers apply it themselves rather than trusting
        /// the models, because `PoliceCall` and `Incident` are public and can be built by hand.
        ///
        /// A *one-sided* intersection — `"BONIS AVE - "` — has letters in it, so it survives this and
        /// is kept as published. What to do with the Service's dangling separator is a display
        /// decision, and a parser is the wrong place to make it.
        private func published(_ raw: String?) -> String? {
            guard let raw, raw.contains(where: { $0.isLetter || $0.isNumber }) else { return nil }
            return raw
        }
    }
}
