import Foundation
@testable import WatchTracker

/// Lock-guarded because `AIServiceProtocol` is `Sendable` and `resolveToMedia`
/// is called concurrently from the view model's task group.
@available(iOS 26, *)
final class MockAIService: AIServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()

    // MARK: - Configurable results

    private var _availability: AIModelAvailability = .available
    private var _generateResult: Result<[AISuggestionItem], Error> = .success([])
    /// Keyed by suggestion title. A missing key resolves to `defaultResolveResult`.
    private var _resolveResults: [String: Result<MediaDetail?, Error>] = [:]
    private var _defaultResolveResult: Result<MediaDetail?, Error> = .success(nil)

    var availability: AIModelAvailability {
        get { lock.withLock { _availability } }
        set { lock.withLock { _availability = newValue } }
    }
    var generateResult: Result<[AISuggestionItem], Error> {
        get { lock.withLock { _generateResult } }
        set { lock.withLock { _generateResult = newValue } }
    }
    var resolveResults: [String: Result<MediaDetail?, Error>] {
        get { lock.withLock { _resolveResults } }
        set { lock.withLock { _resolveResults = newValue } }
    }
    var defaultResolveResult: Result<MediaDetail?, Error> {
        get { lock.withLock { _defaultResolveResult } }
        set { lock.withLock { _defaultResolveResult = newValue } }
    }

    // MARK: - Call tracking

    private var _generateCalls: [(watchlist: [WatchItem], userInput: String)] = []
    private var _resolveCalls: [String] = []

    var generateCalls: [(watchlist: [WatchItem], userInput: String)] { lock.withLock { _generateCalls } }
    var generateCallCount: Int { generateCalls.count }
    var resolveCalls: [String] { lock.withLock { _resolveCalls } }

    // MARK: - Protocol conformance

    func checkAvailability() -> AIModelAvailability { availability }

    func generateSuggestions(from watchlist: [WatchItem], userInput: String) async throws -> [AISuggestionItem] {
        lock.withLock { _generateCalls.append((watchlist: watchlist, userInput: userInput)) }
        return try generateResult.get()
    }

    func resolveToMedia(_ suggestion: AISuggestionItem) async throws -> MediaDetail? {
        lock.withLock { _resolveCalls.append(suggestion.title) }
        return try (resolveResults[suggestion.title] ?? defaultResolveResult).get()
    }
}

/// `AISuggestionItem` is `@Generable` but still a plain struct with a memberwise init.
@available(iOS 26, *)
extension AISuggestionItem {
    static func fixture(
        title: String = "Dune",
        mediaType: String = "movie",
        reason: String = "Because you liked Arrival."
    ) -> AISuggestionItem {
        AISuggestionItem(title: title, mediaType: mediaType, reason: reason)
    }
}
