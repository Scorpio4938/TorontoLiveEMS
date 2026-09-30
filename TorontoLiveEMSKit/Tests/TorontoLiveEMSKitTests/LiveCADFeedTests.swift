import Foundation
import Testing

// A plain import, not `@testable`: these tests go through the public interface,
// which is the only thing the app can see either.
import TorontoLiveEMSKit

@Suite("Live CAD feed source")
struct LiveCADFeedTests {

    /// The expected value is the URL ADR-0001 documents, quoted from the ADR — not a
    /// recomputation of the constant under test.
    @Test("is the endpoint recorded in ADR-0001")
    func endpointMatchesADR() {
        #expect(LiveCADFeed.urlString == "https://www.toronto.ca/data/fire/livecad.xml")
    }

    @Test("is a well-formed HTTPS URL on the City's host")
    func isWellFormedHTTPSURL() throws {
        let url = try #require(URL(string: LiveCADFeed.urlString))

        #expect(url.scheme == "https")
        #expect(url.host() == "www.toronto.ca")
        #expect(url.path() == "/data/fire/livecad.xml")
    }
}
