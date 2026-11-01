import Foundation

/// One Wikipedia or Wikimedia Commons entry used by a reference page.
public struct WikipediaEntry: Sendable, Equatable, Decodable {

    /// The page, section or file title.
    public let title: String

    /// The page or file to open for the full source.
    public let url: String

    /// The excerpt shown on the page, when this is a text entry.
    public let extract: String?

    /// The licence of the text or image named by this entry.
    public let licence: String

    /// The date this entry was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    /// The Wikipedia revision the text came from, when the API returned one.
    public let revision: String?

    /// One photograph, when this entry is an image rather than an excerpt.
    public let image: WikipediaImage?
}

/// One Wikimedia Commons photograph and the attribution that must travel with it.
public struct WikipediaImage: Sendable, Equatable, Decodable {

    /// The scaled image URL to display.
    public let url: String

    /// The Commons file page, where the full attribution lives.
    public let pageURL: String

    /// The photographer or uploader named by Commons.
    public let author: String

    /// The image's own licence, which can differ from the text licence.
    public let licence: String
}

/// The optional Wikipedia material: station histories and unit photographs.
///
/// **Incomplete on purpose.** Wikipedia has histories for only some current stations, and there is
/// no individual article for a division or a unit. A page with no entry gets no Wikipedia section,
/// rather than a repeated general paragraph or an invented fact. The file says which entities have
/// something, and the page asks for its own entry.
///
/// **Text and images carry separate licences.** The station text is CC BY-SA 4.0. A Commons
/// photograph keeps its own licence and author, so the image entry states them and the page shows
/// both with a link to the file page.
public struct WikipediaReference: Sendable {

    /// The page the station text comes from.
    public let source: String

    /// The licence summary for the file. Individual entries state their own licences too.
    public let licence: String

    /// The date the file was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    private let stations: [String: WikipediaEntry]
    private let units: [String: WikipediaEntry]

    /// The Wikipedia entry for a station number, or `nil` when there is none.
    public func station(number: Int) -> WikipediaEntry? {
        stations[String(number)]
    }

    /// The Wikipedia entry for a unit code, or `nil` when there is none.
    public func unit(code: String) -> WikipediaEntry? {
        units[code]
    }

    /// The entries that shipped with the app — or an empty set.
    public static let bundled: WikipediaReference = {
        guard
            let url = Bundle.module.url(
                forResource: "TorontoWikipedia",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let reference = try? WikipediaReference(data: data)
        else {
            return WikipediaReference()
        }
        return reference
    }()

    /// Reads the generated file.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)
        self.source = document.source
        self.licence = document.licence
        self.retrieved = document.retrieved
        self.stations = document.stations
        self.units = document.units
    }

    private init() {
        self.source = ""
        self.licence = ""
        self.retrieved = ""
        self.stations = [:]
        self.units = [:]
    }
}

private extension WikipediaReference {

    struct Document: Decodable {
        let source: String
        let licence: String
        let retrieved: String
        let stations: [String: WikipediaEntry]
        let units: [String: WikipediaEntry]
    }
}
