import Foundation

/// What the user picked on the filter screen, and the only thing that knows how to turn
/// that into a `DiscoverQuery`.
///
/// The type is required rather than optional. TMDB genre ids are type-specific (28 is Action
/// for a movie, a show uses 10759 Action & Adventure), the "newest" sort key differs between
/// the two, and — the deciding reason — merging two independently paginated responses
/// destroys any ordering: a rating sort would come back 9.1, 8.4, 8.9, 8.2.
struct DiscoverFilter: Hashable, Sendable {
    var type: DiscoverType = .movie
    var genreIds: Set<Int> = []
    var sort: DiscoverSort = .popularity
    var providerIds: Set<Int> = []
    var releaseWindow: ReleaseWindow = .any

    /// Drives the badge on the Discover toolbar button. The type is always set, so it is not
    /// something the user "added" and does not count.
    var activeCriteriaCount: Int {
        var count = genreIds.count + providerIds.count
        if sort != .popularity { count += 1 }
        if releaseWindow != .any { count += 1 }
        return count
    }

    func query(page: Int?) -> DiscoverQuery {
        let mediaType = type.mediaType
        return DiscoverQuery(
            type: mediaType,
            genres: genresQueryValue,
            originCountry: type.originCountry,
            providers: providersQueryValue,
            // Provider availability is region-scoped in TMDB, so the region only means
            // something when a provider was actually picked.
            watchRegion: providerIds.isEmpty ? nil : MediaMerge.watchRegion,
            sortBy: sort.queryValue(for: mediaType),
            page: page,
            releaseDateGte: mediaType == .movie ? releaseWindow.from : nil,
            releaseDateLte: mediaType == .movie ? releaseWindow.until : nil,
            firstAirDateGte: mediaType == .tv ? releaseWindow.from : nil,
            firstAirDateLte: mediaType == .tv ? releaseWindow.until : nil,
            voteCountGte: sort.minimumVoteCount
        )
    }

    /// Comma-joined, which is AND in TMDB: picking Thriller and Drama asks for titles that
    /// are both. Anime adds Animation to that set, so "anime + mystery" stays a real query.
    private var genresQueryValue: String? {
        var ids = genreIds
        if let required = type.requiredGenreId { ids.insert(required) }
        guard !ids.isEmpty else { return nil }
        return ids.sorted().map(String.init).joined(separator: ",")
    }

    private var providersQueryValue: String? {
        guard !providerIds.isEmpty else { return nil }
        // Pipe is OR: the user wants titles on any service they subscribe to.
        return providerIds.sorted().map(String.init).joined(separator: "|")
    }
}

/// What the user is browsing for.
///
/// Anime is here rather than being a separate toggle because that is how people pick it —
/// alongside "filme" and "série", not as a modifier on top of one. TMDB has no anime type,
/// so it resolves to Japanese animated series.
enum DiscoverType: String, CaseIterable, Hashable, Sendable, Identifiable {
    case movie
    case tv
    case anime

    var id: String { rawValue }

    /// The TMDB type this actually queries.
    var mediaType: MediaType {
        self == .movie ? .movie : .tv
    }

    /// TMDB has no "anime" flag: it is animation (genre 16) produced in Japan.
    var requiredGenreId: Int? {
        self == .anime ? 16 : nil
    }

    var originCountry: String? {
        self == .anime ? "JP" : nil
    }

    /// Plural throughout: these are chips that filter a whole list, not a badge naming one
    /// title, so they share the watchlist picker's labels rather than `MediaTypeLabel`.
    var title: String {
        switch self {
        case .movie: Strings.MediaFilter.movies
        case .tv: Strings.MediaFilter.tv
        case .anime: Strings.MediaFilter.anime
        }
    }
}

/// How the filtered results are ordered.
enum DiscoverSort: String, CaseIterable, Hashable, Sendable, Identifiable {
    case popularity
    case rating
    case newest
    case titleAZ

    var id: String { rawValue }

    /// "Newest" is the only one that changes key by type — movies carry a release date,
    /// shows a first air date.
    func queryValue(for type: MediaType) -> String {
        switch self {
        case .popularity: "popularity.desc"
        case .rating: "vote_average.desc"
        case .newest: type == .movie ? "primary_release_date.desc" : "first_air_date.desc"
        case .titleAZ: type == .movie ? "title.asc" : "name.asc"
        }
    }

    /// Sorting by rating with no floor hands back titles with three perfect votes, so the
    /// rating sort — and only it — asks TMDB for a minimum audience.
    var minimumVoteCount: Int? {
        self == .rating ? 300 : nil
    }

    var title: String {
        switch self {
        case .popularity: Strings.DiscoverFilter.sortPopularity
        case .rating: Strings.DiscoverFilter.sortRating
        case .newest: Strings.DiscoverFilter.sortNewest
        case .titleAZ: Strings.DiscoverFilter.sortTitle
        }
    }
}

/// The release period, offered as decades because that is how people describe it —
/// "anos 90" rather than a pair of date pickers.
enum ReleaseWindow: String, CaseIterable, Hashable, Sendable, Identifiable {
    case any
    case decade2020s
    case decade2010s
    case decade2000s
    case decade1990s
    case decade1980s
    case before1980

    var id: String { rawValue }

    /// The inclusive start of the window, or nil when it is open at that end.
    var from: String? {
        guard let year = startYear else { return nil }
        return "\(year)-01-01"
    }

    /// The inclusive end of the window, or nil when it is open at that end.
    var until: String? {
        switch self {
        case .any: nil
        case .before1980: "1979-12-31"
        default: startYear.map { "\($0 + 9)-12-31" }
        }
    }

    private var startYear: Int? {
        switch self {
        case .any, .before1980: nil
        case .decade2020s: 2020
        case .decade2010s: 2010
        case .decade2000s: 2000
        case .decade1990s: 1990
        case .decade1980s: 1980
        }
    }

    var title: String {
        switch self {
        case .any: Strings.DiscoverFilter.anyDecade
        case .before1980: Strings.DiscoverFilter.before1980
        default: Strings.DiscoverFilter.decade(startYear ?? 0)
        }
    }
}
