import Foundation

struct ResolvedSuggestion: Identifiable {
    let id: Int
    let suggestion: AISuggestionItem
    let media: MediaDetail
    
    init(suggestion: AISuggestionItem, media: MediaDetail) {
        self.id = media.id
        self.suggestion = suggestion
        self.media = media
    }
}

@Observable
@MainActor
final class AISuggestionsViewModel {
    var availability: AIModelAvailability
    var suggestions: [ResolvedSuggestion] = []
    var isLoading = false
    var errorMessage: String?
    var hasGenerated = false
    var userInput: String = ""

    private let aiService = AIService()
    private let watchlistService = WatchlistService()
    private let store = WatchlistStore.shared

    init() {
        availability = AIService().checkAvailability()
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
                watchlist = try await watchlistService.fetchWatchlist()
            }
            
            guard !watchlist.isEmpty else {
                errorMessage = Strings.AI.emptyWatchlistSubtitle
                isLoading = false
                return
            }
            
            let aiItems = try await aiService.generateSuggestions(from: watchlist, userInput: userInput)
            let watchlistTmdbIds = Set(watchlist.map(\.tmdbId))
            let resolved = await resolveMedia(aiItems, excluding: watchlistTmdbIds)
            
            suggestions = resolved
            hasGenerated = true
        } catch {
            errorMessage = error.localizedDescription
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
