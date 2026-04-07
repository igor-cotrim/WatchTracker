import SwiftUI

struct ProviderBrowseView: View {
    let provider: StreamingProvider

    @State private var results: [MediaDetail] = []
    @State private var isLoading = true
    @State private var currentPage = 1

    private let service = DiscoverService()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if isLoading && results.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(results) { item in
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

                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            Task { await loadMore() }
                        }
                }
                .padding()
            }
        }
        .navigationTitle(provider.providerName)
        .task {
            await fetchResults()
        }
    }

    private func fetchResults() async {
        isLoading = true
        do {
            results = try await service.discoverFiltered(
                type: "movie",
                providers: String(provider.providerId),
                watchRegion: "BR"
            )
        } catch {
            // Silently handle
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        currentPage += 1
        do {
            let more = try await service.discoverFiltered(
                type: "movie",
                providers: String(provider.providerId),
                watchRegion: "BR",
                page: currentPage
            )
            results.append(contentsOf: more)
        } catch {
            currentPage -= 1
        }
        isLoading = false
    }
}
