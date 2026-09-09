import Foundation

@available(iOS 26, *)
@Observable
@MainActor
final class AISuggestionsViewModel {
    private(set) var availability: AIModelAvailability
    private(set) var suggestions: [ResolvedSuggestion] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var hasGenerated = false

    /// The one writable property: it is the prompt field's binding.
    var userInput: String = ""

    private let aiService: any AIServiceProtocol
    private let watchlistService: any WatchlistServiceProtocol
    private let store: WatchlistStore

    init(
        aiService: any AIServiceProtocol,
        watchlistService: any WatchlistServiceProtocol,
        store: WatchlistStore
    ) {
        self.aiService = aiService
        self.watchlistService = watchlistService
        self.store = store
        availability = aiService.checkAvailability()
    }

    func generateSuggestions() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        suggestions = []
        
        do {
            let watchlist: [WatchItem]
            if !store.cachedItems.isEmpty {
                watchlist = store.cachedItems
            } else {
                watchlist = try await watchlistService.fetchWatchlist(status: nil, mediaType: nil)
            }

            let aiItems = try await aiService.generateSuggestions(from: watchlist, userInput: userInput)
            let watchlistTmdbIds = Set(watchlist.map(\.tmdbId))
            let resolved = await resolveMedia(aiItems, excluding: watchlistTmdbIds)
            
            suggestions = resolved
            hasGenerated = true
        } catch {
            errorMessage = error.userFacingMessage
        }
        
        isLoading = false
    }
    
    func refresh() async {
        hasGenerated = false
        await generateSuggestions()
    }
    
    // MARK: - Private
    
    private func resolveMedia(
        _ items: [AISuggestionItem],
        excluding watchlistIds: Set<Int>
    ) async -> [ResolvedSuggestion] {
        await withTaskGroup(of: ResolvedSuggestion?.self) { group in
            var results: [ResolvedSuggestion] = []
            var running = 0

            for item in items {
                if running >= 3 {
                    if let result = await group.next() {
                        if let result { results.append(result) }
                    }
                    running -= 1
                }

                group.addTask { [aiService] in
                    guard let media = try? await aiService.resolveToMedia(item) else {
                        return nil
                    }
                    // Skip titles already in the user's watchlist
                    guard !watchlistIds.contains(media.id) else {
                        return nil
                    }
                    return await ResolvedSuggestion(
                        suggestion: item,
                        media: media
                    )
                }
                running += 1
            }

            for await result in group {
                if let result { results.append(result) }
            }

            return results
        }
    }
}
