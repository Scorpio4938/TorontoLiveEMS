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

    /// The layer's own last-edit time, out of the layer's metadata.
    ///
    /// A second response from the same service, and the only place the app can learn when the Service
    /// last wrote — a `query` cannot be asked for it.
    ///
    /// **The Service's latest stamp, not an as-of.** It can describe a write whose calls the screen
    /// has not fetched; `PoliceCallFeed` keeps the stamp those calls were read under separately.
    ///
    /// `dataLastEditDate` rather than `lastEditDate`: both are present and equal in this service, and
    /// the one whose name says "the data" is the one whose meaning can be stated.
    ///
    /// **Non-throwing, and optional.** A response without a stamp means "no proof the calls are
    /// current, and no time to quote", which is a state the feed handles by fetching; it is not a
    /// failure worth putting in front of a reader, and it must not be confused with a network failure,
    /// which the client reports.
    public static func latestStamp(from data: Data) -> Date? {
        guard let layer = try? JSONDecoder().decode(Layer.self, from: data),
              let milliseconds = layer.editingInfo?.dataLastEditDate
        else {
            return nil
        }
        // Milliseconds since 1970, as published — the same unit as OCCURRENCE_TIME.
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }

    private struct Layer: Decodable {
        let editingInfo: EditingInfo?

        struct EditingInfo: Decodable {
            let dataLastEditDate: Double?
        }
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
