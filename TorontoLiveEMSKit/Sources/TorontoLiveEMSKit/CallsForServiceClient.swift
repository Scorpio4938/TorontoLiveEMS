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

    /// A session that gives up in fifteen seconds rather than sixty, and never serves a cached answer.
    ///
    /// **Both settings come from a measurement.** Tapping refresh on the police page while the service
    /// was unreachable left the app looking dead for the better part of a minute: `URLSession.shared`
    /// waits sixty seconds by default, and a tap can make two requests. Fifteen is generous for thirty
    /// kilobytes and short enough that a reader is told something. It is the *inactivity* timeout, so a
    /// slow connection that keeps moving is not cut off.
    ///
    /// **Ignoring the cache is correctness rather than tuning.** The metadata address is the same on
    /// every request, so a cached answer would hand the app a stale write time — and that time is what
    /// decides whether a refresh fetches the calls at all.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    public init() {}

    /// The calls in the four hours ending at `now`.
    public func calls(now: Date = Date()) async throws -> [PoliceCall] {
        guard let url = CallsForServiceFeed.queryURL(now: now) else {
            throw CallsForServiceClientError.invalidURL
        }

        let (data, response) = try await Self.session.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CallsForServiceClientError.unexpectedStatus(http.statusCode)
        }

        return try CallsForServiceParser.parse(data)
    }

    /// The Service's latest write time, as the layer states it.
    ///
    /// **A request of its own, and the value the police feed compares on every refresh.** The time is
    /// in the layer's metadata rather than in a query response, so this asks the layer about itself:
    /// 10.5 KB, against 22.7 KB for the calls. The calls are fetched only when this stamp is not the
    /// one they were read under — so the request is what stops a write the screen has not seen from
    /// being refused.
    ///
    /// **The latest stamp, not an as-of.** It may describe a write whose calls the screen has never
    /// fetched; `PoliceCallFeed` keeps the as-of separately, and that is what the status line quotes.
    ///
    /// Answered as an optional: a layer that has stopped stating a time means "no proof the calls are
    /// current", not "a failure". A network failure still throws, because that is a different thing.
    public func latestStamp() async throws -> Date? {
        guard let url = CallsForServiceFeed.layerURL else {
            throw CallsForServiceClientError.invalidURL
        }

        let (data, response) = try await Self.session.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CallsForServiceClientError.unexpectedStatus(http.statusCode)
        }

        return CallsForServiceParser.latestStamp(from: data)
    }
}
