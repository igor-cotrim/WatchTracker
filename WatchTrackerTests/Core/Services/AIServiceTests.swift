import Foundation
import Testing
import FoundationModels
@testable import WatchTracker

/// `AIService` is `@available(iOS 26, *)` but Swift Testing rejects `@available` on a
/// `@Test` function, so every test guards at runtime instead. The bulk of the logic
/// lives in the ungated `AIPromptBuilder` and is covered by `AIPromptBuilderTests`.
@MainActor
@Suite("AIService", .tags(.service, .async), .timeLimit(.minutes(1)))
struct AIServiceTests {

    // MARK: - Availability mapping

    @Test func `availability maps the available case`() {
        guard #available(iOS 26, *) else { return }
        #expect(AIService.availability(for: .available) == .available)
    }

    @Test func `availability maps an ineligible device`() {
        guard #available(iOS 26, *) else { return }
        #expect(AIService.availability(for: .unavailable(.deviceNotEligible)) == .notEligible)
    }

    @Test func `availability maps Apple Intelligence being off`() {
        guard #available(iOS 26, *) else { return }
        #expect(AIService.availability(for: .unavailable(.appleIntelligenceNotEnabled)) == .notEnabled)
    }

    @Test func `availability maps a model that is still downloading`() {
        guard #available(iOS 26, *) else { return }
        #expect(AIService.availability(for: .unavailable(.modelNotReady)) == .notReady)
    }

    // MARK: - generateSuggestions

    @Test func `generateSuggestions returns the model's suggestions`() async throws {
        guard #available(iOS 26, *) else { return }
        let generator = StubGenerator()
        generator.response = .success(AISuggestionsResponse(suggestions: [
            .fixture(title: "Dune"), .fixture(title: "Arrival")
        ]))

        let items = try await makeService(generator: generator)
            .generateSuggestions(from: [], userInput: "")

        #expect(items.map(\.title) == ["Dune", "Arrival"])
    }

    @Test func `generateSuggestions passes the built prompt and instructions through`() async throws {
        guard #available(iOS 26, *) else { return }
        let generator = StubGenerator()
        let service = makeService(generator: generator)

        _ = try await service.generateSuggestions(from: [], userInput: "space opera")

        let call = try #require(generator.calls.first)
        #expect(call.prompt == service.promptBuilder.buildPrompt(from: [], userInput: "space opera"))
        #expect(call.instructions == service.promptBuilder.instructions)
    }

    @Test func `generateSuggestions propagates a model failure`() async {
        guard #available(iOS 26, *) else { return }
        let generator = StubGenerator()
        generator.response = .failure(MockError.generic("model unavailable"))

        await #expect(throws: MockError.self) {
            _ = try await makeService(generator: generator).generateSuggestions(from: [], userInput: "")
        }
    }

    // MARK: - resolveToMedia

    @Test func `resolveToMedia searches for movies as movies`() async throws {
        guard #available(iOS 26, *) else { return }
        let discover = MockDiscoverService()
        discover.searchResult = .success([TestFixtures.mediaDetail(id: 550)])

        let media = try await makeService(discover: discover)
            .resolveToMedia(.fixture(title: "Fight Club", mediaType: "movie"))

        #expect(media?.id == 550)
        #expect(discover.lastSearchQuery == "Fight Club")
    }

    /// The mapping is `"movie"` or else TV, so anything unexpected from the model —
    /// including an empty string or a differently-cased `"MOVIE"` — is searched as a show.
    @Test(arguments: ["tv", "", "series", "MOVIE"])
    func `any media type other than movie is searched as TV`(mediaType: String) async throws {
        guard #available(iOS 26, *) else { return }
        let discover = MockDiscoverService()
        discover.searchResult = .success([TestFixtures.tvDetail(id: 1399)])

        let media = try await makeService(discover: discover)
            .resolveToMedia(.fixture(title: "Some Show", mediaType: mediaType))

        #expect(media?.id == 1399)
    }

    @Test func `resolveToMedia returns the first search hit`() async throws {
        guard #available(iOS 26, *) else { return }
        let discover = MockDiscoverService()
        discover.searchResult = .success([
            TestFixtures.mediaDetail(id: 1), TestFixtures.mediaDetail(id: 2)
        ])

        #expect(try await makeService(discover: discover).resolveToMedia(.fixture())?.id == 1)
    }

    @Test func `resolveToMedia returns nil when the search finds nothing`() async throws {
        guard #available(iOS 26, *) else { return }
        let discover = MockDiscoverService()
        discover.searchResult = .success([])

        #expect(try await makeService(discover: discover).resolveToMedia(.fixture()) == nil)
    }

    @Test func `resolveToMedia propagates a search failure`() async {
        guard #available(iOS 26, *) else { return }
        let discover = MockDiscoverService()
        discover.searchResult = .failure(APIError.serverError)

        await #expect(throws: APIError.serverError) {
            _ = try await makeService(discover: discover).resolveToMedia(.fixture())
        }
    }
}

// MARK: - Helpers

@available(iOS 26, *)
@MainActor
private func makeService(
    // Defaults are `nil` rather than fresh instances because a default argument is
    // evaluated outside this function's `@MainActor` context.
    discover: MockDiscoverService? = nil,
    generator: (any AISuggestionGenerating)? = nil,
    locale: Locale = Locale(identifier: "en_US")
) -> AIService {
    AIService(
        discoverService: discover ?? MockDiscoverService(),
        generator: generator ?? StubGenerator(),
        promptBuilder: AIPromptBuilder(locale: locale)
    )
}

/// Returns whatever it is configured with, and records the prompt it was given.
@available(iOS 26, *)
private final class StubGenerator: AISuggestionGenerating, @unchecked Sendable {
    private let lock = NSLock()
    private var _response: Result<AISuggestionsResponse, Error> =
        .success(AISuggestionsResponse(suggestions: [AISuggestionItem.fixture()]))
    private var _calls: [(prompt: String, instructions: String)] = []

    var response: Result<AISuggestionsResponse, Error> {
        get { lock.withLock { _response } }
        set { lock.withLock { _response = newValue } }
    }
    var calls: [(prompt: String, instructions: String)] { lock.withLock { _calls } }

    func respond(to prompt: String, instructions: String) async throws -> AISuggestionsResponse {
        lock.withLock { _calls.append((prompt: prompt, instructions: instructions)) }
        return try response.get()
    }
}
