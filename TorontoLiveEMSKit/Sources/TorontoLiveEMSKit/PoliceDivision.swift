import Foundation

/// One police division, as the City of Toronto publishes it.
///
/// **A number and nothing else.** The published boundary file carries 19 features, each with a
/// division number, and this type keeps that number. The geometry is not shipped: no screen draws
/// a division boundary, and a polygon nothing reads is a second copy of a published shape waiting
/// to drift.
public struct PoliceDivision: Sendable, Equatable, Identifiable, Decodable {

    public var id: String { number }

    /// The division number as the City publishes it, e.g. `14`.
    ///
    /// **This is the only form a screen shows.** The feed spells the same division `D14`, and the
    /// app must not show both spellings as if they were two things. `PoliceDivisions` accepts
    /// either on the way in and hands back this one canonical value.
    public let number: String
}

/// The police divisions the City publishes boundaries for, and where the file came from.
///
/// **Why this exists.** A police call arrives with a division string — `D14` — and the City also
/// publishes which divisions exist as 19 boundary features. The boundary file spells the same
/// division `14`. One of the two has to be normalised, and this type makes the City's spelling the
/// canonical one: the file stores `14`, a lookup accepts `14` or `D14`, and a screen renders
/// `number` so the app can never show both.
///
/// **19 divisions, including `00`.** The published file carries all 19 rows, so the file the app
/// ships does too. Nothing here decides which divisions are interesting: a division the City
/// publishes is a division the app can name.
///
/// `scripts/make_reference_data.py` writes the file, and re-running that script is the only way it
/// changes.
public struct PoliceDivisions: Sendable {

    /// Where the file came from. Required by the licence, and traceable to a URL rather than to
    /// memory.
    public let source: String

    /// The licence the published source is released under.
    public let licence: String

    /// The date the file was retrieved, `yyyy-MM-dd`.
    public let retrieved: String

    private let byNumber: [String: PoliceDivision]

    /// How many divisions the file holds.
    public var count: Int { byNumber.count }

    /// Every division, in number order.
    public var divisions: [PoliceDivision] {
        byNumber.values.sorted { $0.number < $1.number }
    }

    /// The division a published value names, accepting either the City's `14` or the feed's
    /// `D14`.
    ///
    /// Case does not matter, and surrounding whitespace is ignored. A value the file does not hold
    /// returns `nil` rather than a made-up division.
    public func division(forPublished published: String) -> PoliceDivision? {
        byNumber[Self.normalised(published)]
    }

    /// The divisions that shipped with the app — or an empty set.
    ///
    /// Empty rather than fatal when the resource is missing or unreadable, because a screen that
    /// cannot name a division can still show the feed's own string, and a worse answer beats a
    /// crash. The tests assert that the resource does load, so a packaging mistake fails there
    /// rather than shipping quietly.
    public static let bundled: PoliceDivisions = {
        guard
            let url = Bundle.module.url(
                forResource: "TorontoPoliceDivisions",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let divisions = try? PoliceDivisions(data: data)
        else {
            return PoliceDivisions()
        }
        return divisions
    }()

    /// Reads the generated file.
    ///
    /// Throws rather than returning nothing, so a caller can tell a broken file from an empty one.
    /// `bundled` is the caller that decides to carry on regardless.
    public init(data: Data) throws {
        let document = try JSONDecoder().decode(Document.self, from: data)

        var byNumber: [String: PoliceDivision] = [:]
        for division in document.divisions {
            // Normalise on the way in as well as on the way out, so a file that spells a division
            // two ways is refused rather than silently holding two rows for one division.
            let number = Self.normalised(division.number)
            guard byNumber[number] == nil else {
                throw PoliceDivisionsError.duplicateDivision(number)
            }
            byNumber[number] = PoliceDivision(number: number)
        }

        self.source = document.source
        self.licence = document.licence
        self.retrieved = document.retrieved
        self.byNumber = byNumber
    }

    private init() {
        self.source = ""
        self.licence = ""
        self.retrieved = ""
        self.byNumber = [:]
    }

    private static func normalised(_ published: String) -> String {
        let trimmed = published
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return trimmed.hasPrefix("D") ? String(trimmed.dropFirst()) : trimmed
    }
}

/// What can go wrong reading the file.
public enum PoliceDivisionsError: Error, Equatable {
    /// Two rows name the same division, after normalisation.
    case duplicateDivision(String)
}

private extension PoliceDivisions {

    struct Document: Decodable {
        let source: String
        let licence: String
        let retrieved: String
        let divisions: [PoliceDivision]
    }
}
