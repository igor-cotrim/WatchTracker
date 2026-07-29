import Foundation
import FoundationModels

// MARK: - Protocols

@available(iOS 26, *)
protocol AIServiceProtocol: Sendable {
    func checkAvailability() -> AIModelAvailability
    func generateSuggestions(from watchlist: [WatchItem], userInput: String) async throws -> [AISuggestionItem]
    func resolveToMedia(_ suggestion: AISuggestionItem) async throws -> MediaDetail?
}

/// The one call `AIService` makes into `FoundationModels`. Narrow on purpose: it keeps
/// the `@Generable` generics out of the seam, so a stub is a handful of lines.
@available(iOS 26, *)
protocol AISuggestionGenerating: Sendable {
    func respond(to prompt: String, instructions: String) async throws -> AISuggestionsResponse
}

/// Production generator, and the only place a `LanguageModelSession` is created.
@available(iOS 26, *)
struct LiveAISuggestionGenerator: AISuggestionGenerating {
    func respond(to prompt: String, instructions: String) async throws -> AISuggestionsResponse {
        let session = LanguageModelSession(model: .default, instructions: instructions)
        let response = try await session.respond(to: prompt, generating: AISuggestionsResponse.self)
        return response.content
    }
}

// MARK: - AIService

@available(iOS 26, *)
final class AIService: AIServiceProtocol {
    private let discoverService: any DiscoverServiceProtocol
    private let generator: any AISuggestionGenerating
    let promptBuilder: AIPromptBuilder

    init(
        discoverService: any DiscoverServiceProtocol = DiscoverService(),
        generator: any AISuggestionGenerating = LiveAISuggestionGenerator(),
        promptBuilder: AIPromptBuilder = AIPromptBuilder()
    ) {
        self.discoverService = discoverService
        self.generator = generator
        self.promptBuilder = promptBuilder
    }

    func checkAvailability() -> AIModelAvailability {
        Self.availability(for: SystemLanguageModel.default.availability)
    }

    /// Split from `checkAvailability()` so the mapping can be verified without
    /// depending on the host device's Apple Intelligence state.
    static func availability(for availability: SystemLanguageModel.Availability) -> AIModelAvailability {
        switch availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .notEligible
            case .appleIntelligenceNotEnabled:
                return .notEnabled
            case .modelNotReady:
                return .notReady
            default:
                return .notEligible
            }
        }
    }

    func generateSuggestions(from watchlist: [WatchItem], userInput: String = "") async throws -> [AISuggestionItem] {
        let response = try await generator.respond(
            to: promptBuilder.buildPrompt(from: watchlist, userInput: userInput),
            instructions: promptBuilder.instructions
        )
        return response.suggestions
    }

    /// The model only ever answers `"movie"` or `"tv"`, but it is a free-form string —
    /// anything that is not exactly `"movie"` is searched as a show.
    func resolveToMedia(_ suggestion: AISuggestionItem) async throws -> MediaDetail? {
        let type: MediaType = suggestion.mediaType == "movie" ? .movie : .tv
        let results = try await discoverService.search(query: suggestion.title, type: type, year: nil)
        return results.first
    }
}
