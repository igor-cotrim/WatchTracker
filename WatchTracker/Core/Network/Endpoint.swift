import Foundation

enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case DELETE
    case PATCH
}

enum Endpoint: Sendable {
    // Watchlist
    case watchlist(status: WatchlistStatus? = nil, mediaType: String? = nil)
    case continueWatching
    case watchlistUpcoming
    case addToWatchlist(tmdbId: Int, mediaType: MediaType, status: WatchlistStatus)
    case removeFromWatchlist(id: Int)
    case updateWatchlistStatus(id: Int, status: WatchlistStatus)

    // Media Detail
    case mediaDetail(type: MediaType, id: Int)
    case rateMedia(type: MediaType, id: Int, rating: Int)
    case watchEpisode(tvId: Int, season: Int, episode: Int)
    case unwatchEpisode(tvId: Int, season: Int, episode: Int)
    case watchSeason(tvId: Int, season: Int)
    case unwatchSeason(tvId: Int, season: Int)
    case watchAllEpisodes(tvId: Int)
    case seasonDetail(tvId: Int, season: Int)
    case watchedEpisodes(tvId: Int, season: Int)

    // Profile
    case profileStats

    // Discover
    case discover(provider: String?, type: MediaType?, region: String?)
    case discoverFiltered(type: MediaType, genres: String?, originCountry: String?, providers: String?, watchRegion: String?, sortBy: String?, page: Int?, releaseDateGte: String?, firstAirDateGte: String?)
    case trending(page: Int?)
    case search(query: String, type: MediaType?, year: Int?)
    case nowPlaying(page: Int?)
    case topRated(type: MediaType, page: Int?)
    case upcoming(page: Int?)
    case popular(type: MediaType, page: Int?)
    case genres(type: MediaType)
    case providers(type: MediaType)

    var path: String {
        switch self {
        case .watchlist:
            return "/watchlist"
        case .continueWatching:
            return "/watchlist/continue-watching"
        case .watchlistUpcoming:
            return "/watchlist/upcoming"
        case .addToWatchlist:
            return "/watchlist"
        case .removeFromWatchlist(let id):
            return "/watchlist/\(id)"
        case .updateWatchlistStatus(let id, _):
            return "/watchlist/\(id)/status"
        case .mediaDetail(let type, let id):
            return "/media/\(type.rawValue)/\(id)"
        case .rateMedia(let type, let id, _):
            return "/media/\(type.rawValue)/\(id)/rate"
        case .watchEpisode(let tvId, let season, let episode):
            return "/media/tv/\(tvId)/episodes/\(season)/\(episode)/watch"
        case .unwatchEpisode(let tvId, let season, let episode):
            return "/media/tv/\(tvId)/episodes/\(season)/\(episode)/watch"
        case .watchSeason(let tvId, let season):
            return "/media/tv/\(tvId)/seasons/\(season)/watch"
        case .unwatchSeason(let tvId, let season):
            return "/media/tv/\(tvId)/seasons/\(season)/watch"
        case .watchAllEpisodes(let tvId):
            return "/media/tv/\(tvId)/watch-all"
        case .seasonDetail(let tvId, let season):
            return "/media/tv/\(tvId)/season/\(season)"
        case .watchedEpisodes(let tvId, let season):
            return "/media/tv/\(tvId)/seasons/\(season)/watched"
        case .profileStats:
            return "/profile/stats"
        case .discover, .discoverFiltered:
            return "/discover"
        case .trending:
            return "/discover/trending"
        case .search:
            return "/discover/search"
        case .nowPlaying:
            return "/discover/now-playing"
        case .topRated:
            return "/discover/top-rated"
        case .upcoming:
            return "/discover/upcoming"
        case .popular:
            return "/discover/popular"
        case .genres:
            return "/discover/genres"
        case .providers:
            return "/discover/providers"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .watchlist, .continueWatching, .watchlistUpcoming, .mediaDetail, .seasonDetail, .watchedEpisodes, .discover, .discoverFiltered, .trending, .search, .nowPlaying,
             .topRated, .upcoming, .popular, .genres, .providers, .profileStats:
            return .GET
        case .addToWatchlist, .rateMedia, .watchEpisode, .watchSeason, .watchAllEpisodes:
            return .POST
        case .removeFromWatchlist, .unwatchEpisode, .unwatchSeason:
            return .DELETE
        case .updateWatchlistStatus:
            return .PATCH
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .watchlist(let status, let mediaType):
            var items: [URLQueryItem] = []
            if let status { items.append(URLQueryItem(name: "status", value: status.rawValue)) }
            if let mediaType { items.append(URLQueryItem(name: "media_type", value: mediaType)) }
            return items.isEmpty ? nil : items
        case .discover(let provider, let type, let region):
            var items: [URLQueryItem] = []
            if let provider { items.append(URLQueryItem(name: "provider", value: provider)) }
            if let type { items.append(URLQueryItem(name: "type", value: type.rawValue)) }
            if let region { items.append(URLQueryItem(name: "region", value: region)) }
            return items.isEmpty ? nil : items
        case .discoverFiltered(let type, let genres, let originCountry, let providers, let watchRegion, let sortBy, let page, let releaseDateGte, let firstAirDateGte):
            var items: [URLQueryItem] = [URLQueryItem(name: "type", value: type.rawValue)]
            if let genres { items.append(URLQueryItem(name: "with_genres", value: genres)) }
            if let originCountry { items.append(URLQueryItem(name: "with_origin_country", value: originCountry)) }
            if let providers { items.append(URLQueryItem(name: "with_watch_providers", value: providers)) }
            if let watchRegion { items.append(URLQueryItem(name: "watch_region", value: watchRegion)) }
            if let sortBy { items.append(URLQueryItem(name: "sort_by", value: sortBy)) }
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            if let releaseDateGte { items.append(URLQueryItem(name: "primary_release_date.gte", value: releaseDateGte)) }
            if let firstAirDateGte { items.append(URLQueryItem(name: "first_air_date.gte", value: firstAirDateGte)) }
            return items
        case .search(let query, let type, let year):
            var items: [URLQueryItem] = [URLQueryItem(name: "query", value: query)]
            if let type { items.append(URLQueryItem(name: "type", value: type.rawValue)) }
            if let year { items.append(URLQueryItem(name: "year", value: String(year))) }
            return items
        case .topRated(let type, let page):
            var items: [URLQueryItem] = [URLQueryItem(name: "type", value: type.rawValue)]
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items
        case .upcoming(let page):
            var items: [URLQueryItem] = []
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items.isEmpty ? nil : items
        case .trending(let page), .nowPlaying(let page):
            var items: [URLQueryItem] = []
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items.isEmpty ? nil : items
        case .popular(let type, let page):
            var items: [URLQueryItem] = [URLQueryItem(name: "type", value: type.rawValue)]
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items
        case .genres(let type), .providers(let type):
            return [URLQueryItem(name: "type", value: type.rawValue)]
        default:
            return nil
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .addToWatchlist(let tmdbId, let mediaType, let status):
            return AddToWatchlistBody(tmdbId: tmdbId, mediaType: mediaType, status: status)
        case .rateMedia(_, _, let rating):
            return RateMediaBody(rating: rating)
        case .updateWatchlistStatus(_, let status):
            return UpdateWatchlistStatusBody(status: status)
        default:
            return nil
        }
    }
}

// MARK: - Request Bodies

private struct AddToWatchlistBody: Encodable, Sendable {
    let tmdbId: Int
    let mediaType: MediaType
    let status: WatchlistStatus
}

private struct RateMediaBody: Encodable, Sendable {
    let rating: Int
}

private struct UpdateWatchlistStatusBody: Encodable, Sendable {
    let status: WatchlistStatus
}
