import SwiftUI

struct DiscoverView: View {
    @State private var browse: DiscoverBrowseViewModel
    @State private var search: SearchViewModel

    /// The last filter the user committed, kept so reopening the sheet resumes from it
    /// rather than from a blank form. `appliedFilter` doubles as the navigation trigger.
    @State private var draftFilter = DiscoverFilter()
    @State private var appliedFilter: DiscoverFilter?
    @State private var isShowingFilters = false

    init(container: AppContainer) {
        _browse = State(wrappedValue: container.makeDiscoverBrowseViewModel())
        _search = State(wrappedValue: container.makeSearchViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if search.isSearching {
                        searchSection
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    } else {
                        browseContent
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: search.isSearching)
                .padding(.vertical)
            }
            .navigationTitle(Strings.Discover.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $isShowingFilters) {
                DiscoverFilterView(initialFilter: draftFilter) { filter in
                    draftFilter = filter
                    appliedFilter = filter
                }
            }
            .navigationDestination(item: $appliedFilter) { filter in
                FilteredResultsView(filter: filter)
            }
            .searchable(text: $search.query, prompt: Strings.Discover.searchPrompt)
            .onSubmit(of: .search) {
                Task { await search.search() }
            }
            .onChange(of: search.query) {
                search.queryChanged()
            }
            .task {
                await browse.load()
                search.loadHistory()
            }
        }
    }

    /// Badged with how many criteria are active, so the user can tell at a glance that a
    /// filter is still set without opening the sheet.
    private var filterButton: some View {
        Button {
            isShowingFilters = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .overlay(alignment: .topTrailing) {
                    if draftFilter.activeCriteriaCount > 0 {
                        Circle()
                            .fill(Color.brandAccent)
                            .frame(width: 8, height: 8)
                            .offset(x: 3, y: -2)
                    }
                }
        }
        .accessibilityLabel(
            Strings.DiscoverFilter.buttonAccessibility(activeCount: draftFilter.activeCriteriaCount)
        )
    }

    // MARK: - Browse (non-search) content

    private var browseContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProviderStripView(
                providers: browse.providers,
                selectedProviderId: browse.selectedProvider?.providerId
            ) { provider in
                browse.selectProvider(provider)
            }

            MoodStripView()

            if let provider = browse.selectedProvider {
                providerRows(for: provider)
                    .transition(.opacity)
            } else {
                genericRows
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: browse.selectedProvider?.providerId)
    }

    @ViewBuilder
    private var genericRows: some View {
        VStack(alignment: .leading, spacing: 24) {
            row(Strings.Discover.trending, browse.trending, seeAll: .trending)
            row(Strings.Discover.nowPlaying, browse.nowPlaying, seeAll: .nowPlaying)
            row(Strings.Discover.popular, browse.popular, seeAll: .popularMovies)
            row(Strings.Discover.topRated, browse.topRated, seeAll: .topRatedMovies)
            row(Strings.Discover.upcoming, browse.upcoming, seeAll: .upcoming)
        }
    }

    @ViewBuilder
    private func providerRows(for provider: StreamingProvider) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(ProviderRow.allCases, id: \.self) { providerRow in
                let state = browse.providerRows[providerRow] ?? .loading
                let title = providerRow.title(providerName: provider.providerName)
                let feed = providerRow.seeAllFeed(provider: provider)

                if providerRow.isRanked {
                    if !state.items.isEmpty {
                        RankedMediaRowSection(title: title, items: state.items, seeAllFeed: feed)
                    }
                } else {
                    row(title, state, seeAll: feed)
                }
            }
        }
    }

    /// A row only appears once it has something to show — a still-loading or failed feed
    /// leaves no gap, which is what the screen did before each feed had its own state.
    @ViewBuilder
    private func row(_ title: String, _ state: FeedState, seeAll feed: BrowseFeed) -> some View {
        if !state.items.isEmpty {
            MediaRowSection(title: title, items: state.items, seeAllFeed: feed)
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        Group {
            SearchFilterBar(
                selectedType: $search.selectedType,
                selectedYear: $search.selectedYear
            )

            if !search.suggestions.isEmpty && search.results.isEmpty && !search.isLoading {
                SearchSuggestionsList(suggestions: search.suggestions)
            }

            SearchResultsGrid(
                results: search.results,
                isLoading: search.isLoading
            )

            if search.results.isEmpty && !search.isLoading && search.suggestions.isEmpty {
                SearchHistoryList(
                    history: search.history,
                    onSelect: { search.selectHistoryItem($0) },
                    onRemove: { search.removeHistoryItem($0) },
                    onClear: { search.clearHistory() }
                )
            }
        }
    }
}

#Preview {
    DiscoverView(container: .preview)
        .environment(AppContainer.preview)
}
