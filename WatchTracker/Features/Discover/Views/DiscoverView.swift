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
                        // Search Results
                        searchResultsSection
                    } else {
                        // Trending
                        trendingSection

                        // Now Playing
                        nowPlayingSection
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
                }
            }
            .task {
                async let t: () = viewModel.fetchTrending()
                async let n: () = viewModel.fetchNowPlaying()
                _ = await (t, n)
            }
        }
    }

    // MARK: - Sections

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.trending) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.title != nil ? "movie" : "tv",
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

    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Now Playing")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.nowPlaying) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.title != nil ? "movie" : "tv",
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

    private var searchResultsSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if viewModel.searchResults.isEmpty {
                Text("No results found.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.searchResults) { item in
                        NavigationLink {
                            MediaDetailView(
                                mediaType: item.title != nil ? "movie" : "tv",
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
}

#Preview {
    DiscoverView()
}
