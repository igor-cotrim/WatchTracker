import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isSearching {
                        searchSection
                    } else {
                        trendingSection
                        nowPlayingSection
                        popularSection
                        topRatedSection
                        upcomingSection
                        animeSection
                        genresSection
                        providersSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .searchable(text: $viewModel.searchQuery, prompt: "Search movies & shows")
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
                async let a: () = viewModel.fetchAnime()
                async let g: () = viewModel.fetchGenres()
                async let pr: () = viewModel.fetchProviders()
                _ = await (t, n, p, tr, u, a, g, pr)
                viewModel.loadSearchHistory()
            }
        }
    }

    // MARK: - Reusable Horizontal Row

    private func mediaRowSection(title: String, items: [MediaDetail]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.mediaType,
                                mediaId: item.id
                            )
                        } label: {
                            PosterCardView(
                                url: item.posterURL,
                                title: item.displayTitle
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Topic Sections

    private var trendingSection: some View {
        mediaRowSection(title: "Trending", items: viewModel.trending)
    }

    private var nowPlayingSection: some View {
        mediaRowSection(title: "Now Playing", items: viewModel.nowPlaying)
    }

    private var popularSection: some View {
        mediaRowSection(title: "Popular", items: viewModel.popular)
    }

    private var topRatedSection: some View {
        mediaRowSection(title: "Top Rated", items: viewModel.topRated)
    }

    private var upcomingSection: some View {
        mediaRowSection(title: "Upcoming", items: viewModel.upcoming)
    }

    private var animeSection: some View {
        mediaRowSection(title: "Anime", items: viewModel.anime)
    }

    // MARK: - Genre Browsing

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Genre")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(viewModel.genres) { genre in
                        NavigationLink {
                            GenreBrowseView(genre: genre)
                        } label: {
                            Text(genre.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.brandPrimary.opacity(0.15))
                                .foregroundStyle(Color.brandPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Navegar por \(genre.name)")
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Provider Browsing

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Provider")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(viewModel.providers) { provider in
                        NavigationLink {
                            ProviderBrowseView(provider: provider)
                        } label: {
                            VStack(spacing: 4) {
                                AsyncImage(url: provider.logoURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    default:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(.rect(cornerRadius: 10))

                                Text(provider.providerName)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Navegar por \(provider.providerName)")
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        Group {
            // Search filters
            SearchFilterBar(
                selectedType: $viewModel.selectedSearchType,
                selectedYear: $viewModel.selectedSearchYear
            )

            // Autocomplete suggestions (while typing, before submit)
            if !viewModel.searchSuggestions.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isLoading {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ForEach(viewModel.searchSuggestions) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.mediaType,
                                mediaId: item.id
                            )
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: item.posterURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    default:
                                        Color(.systemGray5)
                                    }
                                }
                                .frame(width: 40, height: 60)
                                .clipShape(.rect(cornerRadius: 4))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayTitle)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if let year = item.releaseYear {
                                        Text(year)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Search results
            searchResultsSection

            // Search history (when no results yet)
            if viewModel.searchResults.isEmpty && !viewModel.isLoading && viewModel.searchSuggestions.isEmpty {
                searchHistorySection
            }
        }
    }

    private var searchResultsSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if !viewModel.searchResults.isEmpty {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.searchResults) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.mediaType,
                                mediaId: item.id
                            )
                        } label: {
                            PosterCardView(
                                url: item.posterURL,
                                title: item.displayTitle
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var searchHistorySection: some View {
        Group {
            if !viewModel.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Searches")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearSearchHistory()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.searchHistory, id: \.self) { query in
                        HStack {
                            Button {
                                viewModel.selectHistoryItem(query)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(.secondary)
                                    Text(query)
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.removeSearchHistoryItem(query)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#Preview {
    DiscoverView()
}
