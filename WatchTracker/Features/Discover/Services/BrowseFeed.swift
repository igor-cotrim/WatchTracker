import Foundation

/// A paginated list of titles Discover can show, and the TMDB query that produces it.
///
/// The row on the Discover screen and the "see all" grid behind it are the same feed, so
/// the query is written once here instead of being rebuilt inside every View that opens one.
enum BrowseFeed: Hashable {
    case trending
    case nowPlaying
    case popularMovies
    case topRatedMovies
    case upcoming
    case mood(MoodPreset)
    /// The "see all" grid behind a provider row. Movies only, matching what the row links to.
    case providerMovies(id: Int, sortBy: String)
    /// Everything the user picked on the filter screen, as one paginated feed.
    case filtered(DiscoverFilter)

    func page(_ page: Int, using service: any DiscoverServiceProtocol) async throws -> [MediaDetail] {
        switch self {
        case .trending:
            return try await service.fetchTrending(page: page)
        case .nowPlaying:
            return try await service.fetchNowPlaying(page: page)
        case .popularMovies:
            return try await service.fetchPopular(type: .movie, page: page)
        case .topRatedMovies:
            return try await service.fetchTopRated(type: .movie, page: page)
        case .upcoming:
            return try await service.fetchUpcoming(page: page)
        case .mood(let preset):
            async let movies = service.discoverFiltered(
                DiscoverQuery(
                    type: .movie,
                    genres: preset.genresQueryValue(for: .movie),
                    sortBy: preset.sortBy,
                    page: page
                )
            )
            async let shows = service.discoverFiltered(
                DiscoverQuery(
                    type: .tv,
                    genres: preset.genresQueryValue(for: .tv),
                    sortBy: preset.sortBy,
                    page: page
                )
            )
            return try await MediaMerge.interleaved(movies, shows)
        case .providerMovies(let id, let sortBy):
            return try await service.discoverFiltered(
                DiscoverQuery(
                    type: .movie,
                    providers: String(id),
                    watchRegion: MediaMerge.watchRegion,
                    sortBy: sortBy,
                    page: page
                )
            )
        case .filtered(let filter):
            return try await service.discoverFiltered(filter.query(page: page))
        }
    }
}

/// One of the four rows Discover shows once a streaming provider is selected. Each fans out
/// to a movie and a TV query and merges them, so a row is a single unit of work to the caller.
enum ProviderRow: CaseIterable {
    case new
    case topTen
    case trending
    case acclaimed

    /// `since` is the ISO day cutoff for `.new`, passed in rather than computed so the
    /// ViewModel keeps owning "now" (and tests keep controlling it).
    func load(
        provider: StreamingProvider,
        since: String,
        using service: any DiscoverServiceProtocol
    ) async throws -> [MediaDetail] {
        let providers = String(provider.providerId)

        switch self {
        case .new:
            async let movies = service.discoverFiltered(
                DiscoverQuery(
                    type: .movie,
                    providers: providers,
                    watchRegion: MediaMerge.watchRegion,
                    sortBy: "primary_release_date.desc",
                    releaseDateGte: since
                )
            )
            async let shows = service.discoverFiltered(
                DiscoverQuery(
                    type: .tv,
                    providers: providers,
                    watchRegion: MediaMerge.watchRegion,
                    sortBy: "first_air_date.desc",
                    firstAirDateGte: since
                )
            )
            return try await MediaMerge.byReleaseDateDesc(movies, shows)

        case .topTen:
            return try await Array(merged(providers, sortBy: "popularity.desc", page: nil, using: service).prefix(10))

        case .trending:
            // Page 2 of popularity on purpose: page 1 is already the top-ten row above it.
            return try await merged(providers, sortBy: "popularity.desc", page: 2, using: service)

        case .acclaimed:
            return try await merged(providers, sortBy: "vote_average.desc", page: nil, using: service)
        }
    }

    private func merged(
        _ providers: String,
        sortBy: String,
        page: Int?,
        using service: any DiscoverServiceProtocol
    ) async throws -> [MediaDetail] {
        async let movies = service.discoverFiltered(
            DiscoverQuery(
                type: .movie,
                providers: providers,
                watchRegion: MediaMerge.watchRegion,
                sortBy: sortBy,
                page: page
            )
        )
        async let shows = service.discoverFiltered(
            DiscoverQuery(
                type: .tv,
                providers: providers,
                watchRegion: MediaMerge.watchRegion,
                sortBy: sortBy,
                page: page
            )
        )
        return try await MediaMerge.interleaved(movies, shows)
    }

    func title(providerName: String) -> String {
        switch self {
        case .new: Strings.Discover.newOnProvider(providerName)
        case .topTen: Strings.Discover.topTenOnProvider(providerName)
        case .trending: Strings.Discover.trendingOnProvider(providerName)
        case .acclaimed: Strings.Discover.acclaimedOnProvider(providerName)
        }
    }

    /// Only the top ten is numbered; the rest are plain poster rows.
    var isRanked: Bool { self == .topTen }

    /// The "see all" grid this row links to, ordered the same way the row was.
    func seeAllFeed(provider: StreamingProvider) -> BrowseFeed {
        let sortBy = switch self {
        case .new: "primary_release_date.desc"
        case .topTen, .trending: "popularity.desc"
        case .acclaimed: "vote_average.desc"
        }
        return .providerMovies(id: provider.providerId, sortBy: sortBy)
    }
}

/// How a movie list and a TV list become one row.
enum MediaMerge {
    /// TMDB scopes provider availability by country, and every provider query in the app is BR.
    static let watchRegion = "BR"

    /// Alternates the two lists so neither type dominates the start of the row.
    static func interleaved(_ a: [MediaDetail], _ b: [MediaDetail]) -> [MediaDetail] {
        var result: [MediaDetail] = []
        result.reserveCapacity(a.count + b.count)
        for i in 0..<max(a.count, b.count) {
            if i < a.count { result.append(a[i]) }
            if i < b.count { result.append(b[i]) }
        }
        return result
    }

    /// Newest first across both types. Movies carry `releaseDate`, shows `firstAirDate`,
    /// and both are `yyyy-MM-dd` strings, so lexicographic order is chronological order.
    static func byReleaseDateDesc(_ a: [MediaDetail], _ b: [MediaDetail]) -> [MediaDetail] {
        (a + b).sorted { lhs, rhs in
            (lhs.releaseDate ?? lhs.firstAirDate ?? "") > (rhs.releaseDate ?? rhs.firstAirDate ?? "")
        }
    }
}
