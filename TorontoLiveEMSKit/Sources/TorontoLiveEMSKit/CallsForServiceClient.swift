import Foundation

public enum CallsForServiceClientError: Error, Equatable {
    /// The query URL could not be formed. Should be unreachable — it is a literal and its
    /// parameters are escaped by `URLComponents`.
    case invalidURL
    /// The service responded with a status outside 200..<300.
    case unexpectedStatus(Int)
}

/// Fetches and parses the Toronto Police Service's calls for service.
///
/// Deliberately a single request with no retry, no cache and no polling — the same terms the fire
/// feed is read on, and for the same reason: it is a public service on somebody else's
/// infrastructure. The app asks once at launch and once per explicit refresh.
///
/// **It asks a question rather than fetching a document**, which is the one way this differs from
/// `LiveCADClient`: the calls are selected by a `where` clause over the last four hours, built by
/// `CallsForServiceFeed.queryURL(now:)`. See that function for the two things about the filter that
/// were measured rather than assumed.
public struct CallsForServiceClient: Sendable {

    public init() {}

    /// The calls in the four hours ending at `now`.
    public func calls(now: Date = Date()) async throws -> [PoliceCall] {
        guard let url = CallsForServiceFeed.queryURL(now: now) else {
            throw CallsForServiceClientError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CallsForServiceClientError.unexpectedStatus(http.statusCode)
        }

        return try CallsForServiceParser.parse(data)
    }

    /// When the Service last wrote to the layer.
    ///
    /// **A request of its own, and the one that makes the gate possible.** The time is in the layer's
    /// metadata rather than in a query response, so this asks the layer about itself: 10.5 KB, against
    /// 22.7 KB for the calls. It is worth the price because the same answer is what the status line
    /// quotes — the request buys the gate and the sentence together.
    ///
    /// Answered as an optional: a layer that has stopped stating a time means "no gate", not
    /// "a failure". A network failure still throws, because that is a different thing.
    public func publishedAt() async throws -> Date? {
        guard let url = CallsForServiceFeed.layerURL else {
            throw CallsForServiceClientError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CallsForServiceClientError.unexpectedStatus(http.statusCode)
        }

        return CallsForServiceParser.publishedAt(from: data)
    }
}
