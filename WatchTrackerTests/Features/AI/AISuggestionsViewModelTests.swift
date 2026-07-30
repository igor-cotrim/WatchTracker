import Foundation
import Testing
@testable import WatchTracker

/// `.enabled(if:)` makes a pre-iOS-26 runtime report these as *skipped* instead of
/// passing without running anything — see `AIRuntime`.
@MainActor
@Suite(
    "AISuggestionsViewModel",
    .tags(.viewModel, .async),
    .timeLimit(.minutes(1)),
    .enabled(if: AIRuntime.isAvailable, "requires an iOS 26 runtime")
)
struct AISuggestionsViewModelTests {

    @available(iOS 26, *)
    private final class Harness {
        let ai = MockAIService()
        let watchlist = MockWatchlistService()
        let store = WatchlistStore()
        let viewModel: AISuggestionsViewModel

        @MainActor
        init() {
            viewModel = AISuggestionsViewModel(aiService: ai, watchlistService: watchlist, store: store)
        }
    }

    /// Wires `count` suggestions that each resolve to a distinct media id starting at `firstId`.
    @available(iOS 26, *)
    private func stubSuggestions(_ harness: Harness, count: Int, firstId: Int = 1000) -> [Int] {
        let items = (0..<count).map { AISuggestionItem.fixture(title: "Title \($0)") }
        harness.ai.generateResult = .success(items)
        var ids: [Int] = []
        var results: [String: Result<MediaDetail?, Error>] = [:]
        for (offset, item) in items.enumerated() {
            let id = firstId + offset
            ids.append(id)
            results[item.title] = .success(TestFixtures.mediaDetail(id: id, title: item.title))
        }
        harness.ai.resolveResults = results
        return ids
    }

    // MARK: - Availability

    @Test func `availability comes from the injected service`() {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        #expect(harness.viewModel.availability == .available)
    }

    // MARK: - Watchlist source

    @Test func `generateSuggestions prefers the cached watchlist over the network`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        harness.store.cachedItems = [TestFixtures.watchItem(tmdbId: 1)]
        _ = stubSuggestions(harness, count: 1)

        await harness.viewModel.generateSuggestions()

        #expect(harness.watchlist.fetchWatchlistCallCount == 0)
        #expect(harness.ai.generateCalls.first?.watchlist.count == 1)
    }

    @Test func `generateSuggestions fetches the watchlist when the cache is empty`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        harness.watchlist.fetchWatchlistResult = .success([TestFixtures.watchItem(tmdbId: 7)])
        _ = stubSuggestions(harness, count: 1)

        await harness.viewModel.generateSuggestions()

        #expect(harness.watchlist.fetchWatchlistCallCount == 1)
        #expect(harness.ai.generateCalls.first?.watchlist.first?.tmdbId == 7)
    }

    @Test func `generateSuggestions forwards the user input to the model`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        _ = stubSuggestions(harness, count: 1)
        harness.viewModel.userInput = "something scary"

        await harness.viewModel.generateSuggestions()

        #expect(harness.ai.generateCalls.first?.userInput == "something scary")
    }

    // MARK: - Resolution and filtering

    @Test func `generateSuggestions publishes the resolved suggestions`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        let ids = stubSuggestions(harness, count: 3)

        await harness.viewModel.generateSuggestions()

        // The task group completes out of order, so compare as a set.
        #expect(Set(harness.viewModel.suggestions.map(\.id)) == Set(ids))
        #expect(harness.viewModel.hasGenerated)
        #expect(harness.viewModel.isLoading == false)
        #expect(harness.viewModel.errorMessage == nil)
    }

    @Test func `titles already in the watchlist are dropped`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        let ids = stubSuggestions(harness, count: 3)
        // The user already has the second suggestion.
        harness.store.cachedItems = [TestFixtures.watchItem(tmdbId: ids[1])]

        await harness.viewModel.generateSuggestions()

        let resolved = Set(harness.viewModel.suggestions.map(\.id))
        #expect(resolved == Set([ids[0], ids[2]]))
    }

    @Test func `a suggestion that fails to resolve is dropped without failing the batch`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        let ids = stubSuggestions(harness, count: 3)
        harness.ai.resolveResults["Title 1"] = .failure(MockError.generic("resolve blew up"))

        await harness.viewModel.generateSuggestions()

        #expect(Set(harness.viewModel.suggestions.map(\.id)) == Set([ids[0], ids[2]]))
        #expect(harness.viewModel.errorMessage == nil)
    }

    @Test func `a suggestion with no search hit is dropped`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        let ids = stubSuggestions(harness, count: 3)
        harness.ai.resolveResults["Title 2"] = .success(nil)

        await harness.viewModel.generateSuggestions()

        #expect(Set(harness.viewModel.suggestions.map(\.id)) == Set([ids[0], ids[1]]))
    }

    /// The task group throttles to 3 in flight; more items than the window must
    /// still all be drained.
    @Test func `every suggestion is resolved even beyond the concurrency window`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        let ids = stubSuggestions(harness, count: 8)

        await harness.viewModel.generateSuggestions()

        #expect(harness.viewModel.suggestions.count == 8)
        #expect(Set(harness.viewModel.suggestions.map(\.id)) == Set(ids))
        #expect(Set(harness.ai.resolveCalls).count == 8)
    }

    // MARK: - Loading, reentrancy and refresh

    @Test func `generateSuggestions clears previous results before running`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        _ = stubSuggestions(harness, count: 2)
        await harness.viewModel.generateSuggestions()
        #expect(harness.viewModel.suggestions.count == 2)

        harness.ai.generateResult = .success([])
        harness.ai.resolveResults = [:]
        await harness.viewModel.generateSuggestions()

        #expect(harness.viewModel.suggestions.isEmpty)
    }

    @Test func `refresh resets hasGenerated and regenerates`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        _ = stubSuggestions(harness, count: 1)
        await harness.viewModel.generateSuggestions()
        #expect(harness.viewModel.hasGenerated)

        await harness.viewModel.refresh()

        #expect(harness.ai.generateCallCount == 2)
        #expect(harness.viewModel.hasGenerated)
    }

    // MARK: - Errors

    @Test func `a model failure surfaces as an error message`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        harness.ai.generateResult = .failure(MockError.generic("model unavailable"))

        await harness.viewModel.generateSuggestions()

        #expect(harness.viewModel.errorMessage != nil)
        #expect(harness.viewModel.isLoading == false)
        #expect(harness.viewModel.hasGenerated == false)
        #expect(harness.viewModel.suggestions.isEmpty)
    }

    @Test func `a watchlist fetch failure surfaces as an error message`() async {
        guard #available(iOS 26, *) else { return }
        let harness = Harness()
        harness.watchlist.fetchWatchlistResult = .failure(APIError.serverError)

        await harness.viewModel.generateSuggestions()

        #expect(harness.viewModel.errorMessage != nil)
        #expect(harness.ai.generateCallCount == 0)
        #expect(harness.viewModel.isLoading == false)
    }
}
