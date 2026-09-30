import Foundation

public enum LiveCADClientError: Error, Equatable {
    /// The feed URL could not be formed. Should be unreachable — it is a literal.
    case invalidURL
    /// The feed responded with a status outside 200..<300.
    case unexpectedStatus(Int)
}

/// Fetches and parses the City's live active-incident feed.
///
/// Deliberately a single request with no retry, no cache and no polling. The feed is
/// an undocumented path on the City's server whose contents cannot change more often
/// than every five minutes, so repeated fetching buys nothing and pressures a service
/// that never advertised this endpoint. See `docs/design-decisions.md`.
public struct LiveCADClient: Sendable {

    public init() {}

    public func snapshot() async throws -> LiveCADSnapshot {
        guard let url = URL(string: LiveCADFeed.urlString) else {
            throw LiveCADClientError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw LiveCADClientError.unexpectedStatus(http.statusCode)
        }

        return try LiveCADParser.parse(data)
    }
}
