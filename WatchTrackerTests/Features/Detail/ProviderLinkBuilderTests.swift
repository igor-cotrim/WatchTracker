import Foundation
import Testing
@testable import WatchTracker

@Suite("ProviderLinkBuilder", .tags(.pure, .service))
struct ProviderLinkBuilderTests {

    private func link(providerId: Int,
                      providerName: String = "Some Provider",
                      title: String = "Dune",
                      justWatchLink: String? = nil) -> ProviderLink? {
        ProviderLinkBuilder.link(
            for: TestFixtures.streamingProvider(providerId: providerId, providerName: providerName),
            title: title,
            justWatchLink: justWatchLink
        )
    }

    // MARK: Known providers

    @Test func `Netflix uses its own search template`() throws {
        let result = try #require(link(providerId: 8, providerName: "Netflix"))
        #expect(result.webURL.absoluteString == "https://www.netflix.com/search?q=Dune")
    }

    @Test func `a known template wins over the JustWatch link`() throws {
        let result = try #require(link(providerId: 8, justWatchLink: "https://justwatch.com/whatever"))
        #expect(result.webURL.host == "www.netflix.com")
    }

    @Test(arguments: [119, 9, 350, 2, 337, 1899, 384, 531, 307, 283, 11, 300])
    func `every templated provider produces a URL carrying the title`(providerId: Int) throws {
        let result = try #require(link(providerId: providerId))
        #expect(result.webURL.absoluteString.contains("Dune"))
    }

    // MARK: App deep links

    @Test(arguments: [
        (id: 119, scheme: "aiv"),
        (id: 9, scheme: "aiv"),
        (id: 283, scheme: "crunchyroll"),
        (id: 337, scheme: "disneyplus"),
        (id: 1899, scheme: "hbomax"),
        (id: 384, scheme: "hbomax"),
        (id: 531, scheme: "paramountplus"),
        (id: 307, scheme: "globoplay"),
    ])
    func `providers with a registered scheme expose an appURL`(id: Int, scheme: String) throws {
        let result = try #require(link(providerId: id))
        #expect(result.appURL?.scheme == scheme)
    }

    @Test func `Netflix has no app scheme registered`() throws {
        let result = try #require(link(providerId: 8))
        #expect(result.appURL == nil)
    }

    // MARK: Fallbacks

    @Test func `an unknown provider falls back to the JustWatch link`() throws {
        let result = try #require(link(providerId: 99999, justWatchLink: "https://www.justwatch.com/br/filme/dune"))
        #expect(result.webURL.absoluteString == "https://www.justwatch.com/br/filme/dune")
    }

    @Test func `an unknown provider without JustWatch falls back to Google`() throws {
        let result = try #require(link(providerId: 99999, providerName: "Obscure TV", title: "Dune"))
        #expect(result.webURL.host == "www.google.com")
        #expect(result.webURL.absoluteString.contains("Dune"))
        #expect(result.webURL.absoluteString.contains("Obscure"))
    }

    @Test func `an unparseable JustWatch link falls back to Google`() throws {
        let result = try #require(link(providerId: 99999, justWatchLink: ""))
        #expect(result.webURL.host == "www.google.com")
    }

    // MARK: Encoding

    @Test func `spaces in the title are percent-encoded`() throws {
        let result = try #require(link(providerId: 8, title: "The Lord of the Rings"))
        #expect(!result.webURL.absoluteString.contains(" "))
        #expect(result.webURL.absoluteString.contains("The%20Lord%20of%20the%20Rings"))
    }

    @Test func `accented titles survive encoding`() throws {
        let result = try #require(link(providerId: 8, title: "Cidade de Deus é ótimo"))
        let decoded = result.webURL.absoluteString.removingPercentEncoding
        #expect(decoded?.contains("é ótimo") == true)
    }

    @Test func `an ampersand in the title does not split the query`() throws {
        let result = try #require(link(providerId: 8, title: "Fire & Blood"))
        let components = URLComponents(url: result.webURL, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.count == 1)
    }
}
