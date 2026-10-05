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

    /// The expected value is the page's own address, taken from the page rather than
    /// recomputed from the constant under test.
    @Test("links to the page a person can open, not to the file the app reads")
    func pageIsSeparateFromTheEndpoint() throws {
        // Held apart on purpose. `urlString` serves the XML, `pageURLString` is the page. They
        // are different documents for different readers, and the feed is undocumented and was
        // never offered to people — so the app links to the second and merely fetches the first.
        #expect(LiveCADFeed.pageURLString != LiveCADFeed.urlString)

        let page = try #require(URL(string: LiveCADFeed.pageURLString))
        #expect(page.scheme == "https")
        #expect(page.host() == "www.toronto.ca")
        #expect(page.path()
            == "/community-people/public-safety-alerts/alerts-notifications/toronto-fire-active-incidents/")
    }

    @Test("names the page the way the City does")
    func pageNameIsTheCitysOwn() {
        #expect(LiveCADFeed.pageName == "Toronto Fire Active Incidents")
    }

    @Test("offers the page as a URL the screens can link to")
    func pageURLIsUsable() throws {
        // The test above checks the string parses. This checks the property the views actually use,
        // because a link built from a URL that did not parse is a row that does nothing at all —
        // which is why the view does not force-unwrap it.
        let url = try #require(LiveCADFeed.pageURL)
        #expect(url.scheme == "https")
        #expect(url.host() == "www.toronto.ca")
    }
}
