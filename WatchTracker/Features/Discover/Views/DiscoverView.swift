import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
                            // Tab Picker
                            Picker("", selection: $viewModel.selectedTab) {
                                Text(verbatim: Strings.Discover.tabMovies).tag(DiscoverTab.movies)
                                Text(verbatim: Strings.Discover.tabTV).tag(DiscoverTab.tv)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.bottom, 24)

                            // Content for selected tab
                            if viewModel.selectedTab == .movies {
                                moviesContent
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            } else {
                                tvContent
                                    .transition(.opacity.combined(with: .offset(y: 8)))
                            }

                            // Shared sections
                            genresSection
                            providersSection
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
            mediaRowSection(
                title: Strings.Discover.trending,
                items: viewModel.trending,
                seeAllViewModel: BrowseGridViewModel { [service] _ in try await service.fetchTrending() }
            )
            mediaRowSection(
                title: Strings.Discover.nowPlaying,
                items: viewModel.nowPlaying,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchNowPlaying() }
            )
            mediaRowSection(
                title: Strings.Discover.popular,
                items: viewModel.popular,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchPopular(type: .movie, page: page) }
            )
            mediaRowSection(
                title: Strings.Discover.topRated,
                items: viewModel.topRated,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchTopRated(type: .movie, page: page) }
            )
            mediaRowSection(
                title: Strings.Discover.upcoming,
                items: viewModel.upcoming,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchUpcoming(page: page) }
            )
        }
    }

    private var tvContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            mediaRowSection(
                title: Strings.Discover.popularTV,
                items: viewModel.popularTV,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchPopular(type: .tv, page: page) }
            )
            mediaRowSection(
                title: Strings.Discover.topRatedTV,
                items: viewModel.topRatedTV,
                seeAllViewModel: BrowseGridViewModel { [service] page in try await service.fetchTopRated(type: .tv, page: page) }
            )
            mediaRowSection(
                title: Strings.Discover.anime,
                items: viewModel.anime,
                seeAllViewModel: BrowseGridViewModel { [service] page in
                    try await service.discoverFiltered(type: .tv, genres: "16", originCountry: "JP", page: page)
                }
            )
        }
    }

    // MARK: - Reusable Section Builder

    private func mediaRowSection(
        title: String,
        items: [MediaDetail],
        seeAllViewModel: BrowseGridViewModel? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: title)
                    .font(.title3.bold())
                Spacer()
                if let vm = seeAllViewModel {
                    NavigationLink {
                        BrowseGridView(viewModel: vm)
                            .navigationTitle(title)
                    } label: {
                        Text(verbatim: Strings.Discover.seeAll)
                            .font(.subheadline)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink {
                            MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
                        } label: {
                            PosterCardView(url: item.posterURL, title: item.displayTitle)
                        }
                        .buttonStyle(PressedButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Genre Browsing

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: Strings.Discover.genres)
                .font(.title3.bold())
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(viewModel.genres) { genre in
                        NavigationLink {
                            GenreBrowseView(genre: genre)
                        } label: {
                            Text(verbatim: genre.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.brandPrimary.opacity(0.15))
                                .foregroundStyle(Color.brandPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PressedButtonStyle())
                        .accessibilityLabel(Strings.Discover.browseAccessibility(genre.name))
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
            Text(verbatim: Strings.Discover.providers)
                .font(.title3.bold())
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
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    default:
                                        RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5))
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(.rect(cornerRadius: 10))

                                Text(verbatim: provider.providerName)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                        .buttonStyle(PressedButtonStyle())
                        .accessibilityLabel(Strings.Discover.browseAccessibility(provider.providerName))
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
            SearchFilterBar(
                selectedType: $viewModel.selectedSearchType,
                selectedYear: $viewModel.selectedSearchYear
            )

            if !viewModel.searchSuggestions.isEmpty && viewModel.searchResults.isEmpty && !viewModel.isLoading {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: Strings.Discover.suggestions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ForEach(viewModel.searchSuggestions) { item in
                        NavigationLink {
                            MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
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
                                    Text(verbatim: item.displayTitle)
                                        .font(.subheadline).fontWeight(.medium)
                                    if let year = item.releaseYear {
                                        Text(verbatim: year)
                                            .font(.caption).foregroundStyle(.secondary)
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

            searchResultsSection

            if viewModel.searchResults.isEmpty && !viewModel.isLoading && viewModel.searchSuggestions.isEmpty {
                searchHistorySection
            }
        }
    }

    private var searchResultsSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            } else if !viewModel.searchResults.isEmpty {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.searchResults) { item in
                        NavigationLink {
                            MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
                        } label: {
                            PosterCardView(url: item.posterURL, title: item.displayTitle)
                        }
                        .buttonStyle(PressedButtonStyle())
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
                        Text(verbatim: Strings.Discover.recentSearches)
                            .font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Button(Strings.Discover.clear) { viewModel.clearSearchHistory() }
                            .font(.caption)
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.searchHistory, id: \.self) { query in
                        HStack {
                            Button {
                                viewModel.selectHistoryItem(query)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath").foregroundStyle(.secondary)
                                    Text(verbatim: query).font(.subheadline)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.removeSearchHistoryItem(query)
                            } label: {
                                Image(systemName: "xmark").font(.caption).foregroundStyle(.tertiary)
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
