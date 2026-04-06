import SwiftUI

struct MediaDetailView: View {
    let mediaType: String
    let mediaId: Int

    @State private var viewModel = MediaDetailViewModel()

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 400)
            } else if let media = viewModel.media {
                VStack(alignment: .leading, spacing: 20) {
                    // Header: backdrop + poster overlay
                    headerSection(media)

                    VStack(alignment: .leading, spacing: 16) {
                        // Title + Rating
                        titleSection(media)

                        // Onde Assistir (Where to Watch)
                        whereToWatchSection(media)

                        // Synopsis
                        synopsisSection(media)

                        // Seasons (TV only)
                        if let seasons = media.seasons, !seasons.isEmpty {
                            seasonsSection(seasons)
                        }

                        // Cast
                        if let cast = media.credits?.cast, !cast.isEmpty {
                            castSection(cast)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .navigationTitle(viewModel.media?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDetails(type: mediaType, id: mediaId)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func headerSection(_ media: MediaDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop
            AsyncImage(url: media.backdropURL) { image in
                image.resizable().aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fill)
            }
            .clipped()

            // Poster overlay
            AsyncImage(url: media.posterURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray4))
            }
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 4)
            .padding(.leading)
            .offset(y: 40)
        }
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private func titleSection(_ media: MediaDetail) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(media.displayTitle)
                .font(.title2.bold())

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.ratingStarFilled)
                    .font(.caption)

                if let voteAverage = media.voteAverage {
                    Text(String(format: "%.1f", voteAverage))
                        .font(.subheadline)
                } else {
                    Text("–")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("  |  ")
                    .foregroundStyle(.secondary)

                Text((media.genres?.map(\.name).joined(separator: ", ")) ?? "–")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // User rating
            if let rating = viewModel.userRating {
                Text("Your rating: \(rating)/10")
                    .font(.caption)
                    .foregroundStyle(Color.brandAccent)
            }

            RatingStarsView(rating: viewModel.userRating ?? 0, maxRating: 10) { newRating in
                Task { await viewModel.rateMedia(rating: newRating) }
            }
        }
    }

    @ViewBuilder
    private func whereToWatchSection(_ media: MediaDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Onde Assistir")
                .font(.headline)

            if let providers = media.watchProviders?.results?["BR"]?.flatrate, !providers.isEmpty {
                HStack(spacing: 8) {
                    ForEach(providers) { provider in
                        StreamingBadgeView(provider: provider)
                    }
                }
            } else {
                Text("No streaming info available for your region.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func synopsisSection(_ media: MediaDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            Text(media.overview ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func seasonsSection(_ seasons: [Season]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seasons")
                .font(.headline)
            ForEach(seasons) { season in
                HStack {
                    AsyncImage(url: season.posterURL) { image in
                        image.resizable().aspectRatio(2/3, contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                    }
                    .frame(width: 50, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading) {
                        Text(season.name)
                            .font(.subheadline.bold())
                        Text("\(season.episodeCount) episodes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func castSection(_ cast: [CastMember]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cast")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cast.prefix(20)) { member in
                        VStack {
                            AsyncImage(url: member.profileURL) { image in
                                image.resizable().aspectRatio(1, contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color(.systemGray5))
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())

                            Text(member.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Text(member.character ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MediaDetailView(mediaType: "movie", mediaId: 550)
    }
}
