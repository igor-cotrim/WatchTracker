import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel(
        service: DiscoverService(),
        searchHistoryManager: SearchHistoryManager()
    )

    // Stored once per view lifetime — prevents allocating new @Observable instances on every body evaluation.
    @State private var trendingGridVM = BrowseGridViewModel { page in try await DiscoverService().fetchTrending(page: page) }
    @State private var nowPlayingGridVM = BrowseGridViewModel { page in try await DiscoverService().fetchNowPlaying(page: page) }
    @State private var popularMoviesGridVM = BrowseGridViewModel { page in try await DiscoverService().fetchPopular(type: .movie, page: page) }
    @State private var topRatedMoviesGridVM = BrowseGridViewModel { page in try await DiscoverService().fetchTopRated(type: .movie, page: page) }
    @State private var upcomingGridVM = BrowseGridViewModel { page in try await DiscoverService().fetchUpcoming(page: page) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isSearching {
                        searchSection
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    } else {
                        browseContent
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.isSearching)
                .padding(.vertical)
            }
            .navigationTitle(Strings.Discover.title)
            .searchable(text: $viewModel.searchQuery, prompt: Strings.Discover.searchPrompt)
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .onChange(of: viewModel.searchQuery) {
                if viewModel.searchQuery.isEmpty {
                    viewModel.searchResults = []
                    viewModel.searchSuggestions = []
                } else {
                    viewModel.fetchSuggestions()
                }
            }
            .task {
                async let t: () = viewModel.fetchTrending()
                async let n: () = viewModel.fetchNowPlaying()
                async let p: () = viewModel.fetchPopular()
                async let tr: () = viewModel.fetchTopRated()
                async let u: () = viewModel.fetchUpcoming()
                async let pr: () = viewModel.fetchProviders()
                _ = await (t, n, p, tr, u, pr)
                viewModel.loadSearchHistory()
                viewModel.restoreLastProviderIfNeeded()
            }
        }
    }

    // MARK: - Browse (non-search) content

    private var browseContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProviderStripView(
                providers: viewModel.providers,
                selectedProviderId: viewModel.selectedProvider?.providerId
            ) { provider in
                viewModel.selectProvider(provider)
            }

            MoodStripView()

            if viewModel.selectedProvider != nil {
                providerScopedSections
                    .transition(.opacity)
            } else {
                genericSections
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedProvider?.providerId)
    }

    // MARK: - Generic Sections

    @ViewBuilder
    private var genericSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !viewModel.trending.isEmpty {
                MediaRowSection(
                    title: Strings.Discover.trending,
                    items: viewModel.trending,
                    seeAllViewModel: trendingGridVM
                )
            }
            if !viewModel.nowPlaying.isEmpty {
                MediaRowSection(
                    title: Strings.Discover.nowPlaying,
                    items: viewModel.nowPlaying,
                    seeAllViewModel: nowPlayingGridVM
                )
            }
            if !viewModel.popular.isEmpty {
                MediaRowSection(
                    title: Strings.Discover.popular,
                    items: viewModel.popular,
                    seeAllViewModel: popularMoviesGridVM
                )
            }
            if !viewModel.topRated.isEmpty {
                MediaRowSection(
                    title: Strings.Discover.topRated,
                    items: viewModel.topRated,
                    seeAllViewModel: topRatedMoviesGridVM
                )
            }
            if !viewModel.upcoming.isEmpty {
                MediaRowSection(
                    title: Strings.Discover.upcoming,
                    items: viewModel.upcoming,
                    seeAllViewModel: upcomingGridVM
                )
            }
        }
    }

    // MARK: - Provider-Scoped Sections

    @ViewBuilder
    private var providerScopedSections: some View {
        if let provider = viewModel.selectedProvider {
            VStack(alignment: .leading, spacing: 24) {
                if !viewModel.newOnProvider.isEmpty {
                    MediaRowSection(
                        title: Strings.Discover.newOnProvider(provider.providerName),
                        items: viewModel.newOnProvider,
                        seeAllViewModel: providerSeeAllViewModel(for: provider, sortBy: "primary_release_date.desc")
                    )
                }
                if !viewModel.topTenOnProvider.isEmpty {
                    RankedMediaRowSection(
                        title: Strings.Discover.topTenOnProvider(provider.providerName),
                        items: viewModel.topTenOnProvider,
                        seeAllViewModel: providerSeeAllViewModel(for: provider, sortBy: "popularity.desc")
                    )
                }
                if !viewModel.trendingOnProvider.isEmpty {
                    MediaRowSection(
                        title: Strings.Discover.trendingOnProvider(provider.providerName),
                        items: viewModel.trendingOnProvider,
                        seeAllViewModel: providerSeeAllViewModel(for: provider, sortBy: "popularity.desc")
                    )
                }
                if !viewModel.acclaimedOnProvider.isEmpty {
                    MediaRowSection(
                        title: Strings.Discover.acclaimedOnProvider(provider.providerName),
                        items: viewModel.acclaimedOnProvider,
                        seeAllViewModel: providerSeeAllViewModel(for: provider, sortBy: "vote_average.desc")
                    )
                }
            }
        }
    }

    private func providerSeeAllViewModel(for provider: StreamingProvider, sortBy: String) -> BrowseGridViewModel {
        let service = DiscoverService()
        let providerId = provider.providerId
        return BrowseGridViewModel { page in
            try await service.discoverFiltered(
                type: .movie,
                providers: String(providerId),
                watchRegion: "BR",
                sortBy: sortBy,
                page: page
            )
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        Group {
            SearchFilterBar(
                selectedType: $viewModel.selectedSearchType,
                selectedYear: $viewModel.selectedSearchYear
            )

            if !viewModel.searchSuggestions.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isLoading {
                SearchSuggestionsList(suggestions: viewModel.searchSuggestions)
            }

            SearchResultsGrid(
                results: viewModel.searchResults,
                isLoading: viewModel.isLoading
            )

            if viewModel.searchResults.isEmpty && !viewModel.isLoading && viewModel.searchSuggestions.isEmpty {
                SearchHistoryList(
                    history: viewModel.searchHistory,
                    onSelect: { viewModel.selectHistoryItem($0) },
                    onRemove: { viewModel.removeSearchHistoryItem($0) },
                    onClear: { viewModel.clearSearchHistory() }
                )
            }
        }
    }
}

#Preview {
    DiscoverView()
}
