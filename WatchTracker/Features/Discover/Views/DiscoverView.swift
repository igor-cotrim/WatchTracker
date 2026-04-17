import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel(
        service: DiscoverService(),
        searchHistoryManager: SearchHistoryManager()
    )

    private let service = DiscoverService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isSearching {
                        searchSection
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Picker("", selection: $viewModel.selectedTab) {
                                Text(verbatim: Strings.Discover.tabMovies).tag(DiscoverTab.movies)
                                Text(verbatim: Strings.Discover.tabTV).tag(DiscoverTab.tv)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.bottom, 24)

                            if viewModel.selectedTab == .movies {
                                moviesContent
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            } else {
                                tvContent
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            }

                            GenresRowSection(genres: viewModel.genres)
                            ProvidersRowSection(providers: viewModel.providers)
                                .padding(.top, 8)
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTab)
                        .transition(.opacity.combined(with: .offset(y: 8)))
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
                async let pt: () = viewModel.fetchPopularTV()
                async let trt: () = viewModel.fetchTopRatedTV()
                async let a: () = viewModel.fetchAnime()
                async let g: () = viewModel.fetchGenres()
                async let pr: () = viewModel.fetchProviders()
                _ = await (t, n, p, tr, u, pt, trt, a, g, pr)
                viewModel.loadSearchHistory()
            }
        }
    }

    // MARK: - Tab Content

    private var moviesContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            MediaRowSection(
                title: Strings.Discover.trending,
                items: viewModel.trending,
                seeAllViewModel: BrowseGridViewModel { [service] _ in try await service.fetchTrending() }
            )
            MediaRowSection(
                title: Strings.Discover.nowPlaying,
                items: viewModel.nowPlaying,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchNowPlaying() }
            )
            MediaRowSection(
                title: Strings.Discover.popular,
                items: viewModel.popular,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchPopular(type: .movie, page: page) }
            )
            MediaRowSection(
                title: Strings.Discover.topRated,
                items: viewModel.topRated,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchTopRated(type: .movie, page: page) }
            )
            MediaRowSection(
                title: Strings.Discover.upcoming,
                items: viewModel.upcoming,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchUpcoming(page: page) }
            )
        }
    }

    private var tvContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            MediaRowSection(
                title: Strings.Discover.popularTV,
                items: viewModel.popularTV,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchPopular(type: .tv, page: page) }
            )
            MediaRowSection(
                title: Strings.Discover.topRatedTV,
                items: viewModel.topRatedTV,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchTopRated(type: .tv, page: page) }
            )
            MediaRowSection(
                title: Strings.Discover.anime,
                items: viewModel.anime,
                seeAllViewModel: BrowseGridViewModel { [service] page in
                    try await service.discoverFiltered(type: .tv, genres: "16", originCountry: "JP", page: page)
                }
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
