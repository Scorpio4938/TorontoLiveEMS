import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// The set of active incidents as published at one moment.
///
/// The feed is a snapshot, not a stream: it carries no clear or close signal, so an
/// incident leaves the set only by disappearing. See
/// `docs/adr/0001-toronto-livecad-xml-as-live-source.md`.
public struct LiveCADSnapshot: Equatable, Sendable {

    /// The feed's own record of when CAD was read, e.g. `2026-09-29 20:00:01`.
    ///
    /// This is the age of the *data*, not of our request, which is why it is the
    /// timestamp worth showing a user.
    public let updatedFromDatabaseAt: String?

    /// The active incidents, in the order published — ascending dispatch time.
    public let incidents: [Incident]

    public init(updatedFromDatabaseAt: String?, incidents: [Incident]) {
        self.updatedFromDatabaseAt = updatedFromDatabaseAt
        self.incidents = incidents
    }
}

public enum LiveCADParserError: Error, Equatable {
    /// The payload was not well-formed XML.
    case malformedPayload
}

/// Parses the City's live active-incident feed.
///
/// `XMLParser` is used rather than `XMLDocument` deliberately: `XMLDocument` is
/// macOS-centric, and this code has to build for every platform the app does.
public enum LiveCADParser {

    public static func parse(_ data: Data) throws -> LiveCADSnapshot {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            throw LiveCADParserError.malformedPayload
        }

        return LiveCADSnapshot(
            updatedFromDatabaseAt: delegate.updatedFromDatabaseAt,
            incidents: delegate.incidents
        )
    }

    /// The delegate's methods are optional requirements of an `@objc` protocol, and
    /// Swift infers `@objc` for a declaration that satisfies a protocol requirement, so
    /// no explicit attribute is needed. Adding one would also make this file
    /// Darwin-only, contradicting the FoundationXML import above.
    final class Delegate: NSObject, XMLParserDelegate {

        var updatedFromDatabaseAt: String?
        var incidents: [Incident] = []

        private var text = ""
        private var fields: [String: String] = [:]
        private var insideEvent = false

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String]
        ) {
            text = ""
            if elementName == "event" {
                insideEvent = true
                fields = [:]
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            defer { text = "" }

            guard insideEvent else {
                if elementName == "update_from_db_time" {
                    updatedFromDatabaseAt = Self.published(text)
                }
                return
            }

            if elementName == "event" {
                incidents.append(Incident(
                    incidentNumber: fields["event_num"] ?? "",
                    primeStreet: Self.published(fields["prime_street"]),
                    crossStreets: Self.published(fields["cross_streets"]),
                    dispatchTime: fields["dispatch_time"] ?? "",
                    incidentType: fields["event_type"] ?? "",
                    alarmLevel: fields["alarm_lev"] ?? "",
                    area: fields["beat"] ?? "",
                    dispatchedUnits: Self.published(fields["units_disp"])
                ))
                insideEvent = false
                fields = [:]
                return
            }

            fields[elementName] = text
        }

        /// Trimmed text, or `nil` when there is nothing in it.
        ///
        /// The feed expresses "not published" three different ways — an empty element
        /// (`<cross_streets/>`), a missing element (`units_disp`), and an XML-escaped
        /// space (`<prime_street>&#x20;</prime_street>`). All three mean the same
        /// thing here, and all three become `nil`.
        private static func published(_ raw: String?) -> String? {
            let trimmed = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }
}
