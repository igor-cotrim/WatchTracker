import SwiftUI

struct WatchingView: View {
    @State private var viewModel = ContinueWatchingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle(Strings.Watching.title)
            .task { await viewModel.fetch() }
            .refreshable { await viewModel.fetch() }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.items) { item in
                WatchingRow(item: item) {
                    Task { await viewModel.markAsWatched(item) }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.markAsWatched(item) }
                    } label: {
                        Label(Strings.Watching.markWatched, systemImage: "checkmark")
                    }
                    .tint(Color.brandPrimary)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(verbatim: Strings.Watching.emptyTitle)
                .font(.headline)
            Text(verbatim: Strings.Watching.emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WatchingRow: View {
    let item: ContinueWatchingItem
    let onMarkWatched: () -> Void

    var body: some View {
        NavigationLink {
            MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                AsyncImage(url: item.stillURL ?? item.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        SkeletonView()
                    }
                }
                .frame(width: 100, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: item.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let next = item.nextEpisode {
                        Text(verbatim: Strings.Watching.episodeLabel(season: next.seasonNumber, episode: next.episodeNumber))
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text(verbatim: next.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Mark watched button
                Button(action: onMarkWatched) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }
}
