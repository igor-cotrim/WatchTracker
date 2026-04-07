import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case DELETE
}

enum Endpoint {
    // Watchlist
    case watchlist
    case addToWatchlist(tmdbId: Int, mediaType: String, status: String)
    case removeFromWatchlist(id: Int)

    // Media Detail
    case mediaDetail(type: String, id: Int)
    case rateMedia(type: String, id: Int, rating: Int)
    case watchEpisode(tvId: Int, season: Int, episode: Int)
    case seasonDetail(tvId: Int, season: Int)

    // Discover
    case discover(provider: String?, type: String?, region: String?)
    case discoverFiltered(type: String, genres: String?, originCountry: String?, providers: String?, watchRegion: String?, sortBy: String?, page: Int?)
    case trending
    case search(query: String, type: String?, year: Int?)
    case nowPlaying
    case topRated(type: String, page: Int?)
    case upcoming(page: Int?)
    case popular(type: String, page: Int?)
    case genres(type: String)
    case providers(type: String)

    var path: String {
        switch self {
        case .watchlist:
            return "/watchlist"
        case .addToWatchlist:
            return "/watchlist"
        case .removeFromWatchlist(let id):
            return "/watchlist/\(id)"
        case .mediaDetail(let type, let id):
            return "/media/\(type)/\(id)"
        case .rateMedia(let type, let id, _):
            return "/media/\(type)/\(id)/rate"
        case .watchEpisode(let tvId, let season, let episode):
            return "/media/tv/\(tvId)/season/\(season)/episode/\(episode)/watch"
        case .seasonDetail(let tvId, let season):
            return "/media/tv/\(tvId)/season/\(season)"
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
        case .watchlist, .mediaDetail, .seasonDetail, .discover, .discoverFiltered, .trending, .search, .nowPlaying,
             .topRated, .upcoming, .popular, .genres, .providers:
            return .GET
        case .addToWatchlist, .rateMedia, .watchEpisode:
            return .POST
        case .removeFromWatchlist:
            return .DELETE
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .discover(let provider, let type, let region):
            var items: [URLQueryItem] = []
            if let provider { items.append(URLQueryItem(name: "provider", value: provider)) }
            if let type { items.append(URLQueryItem(name: "type", value: type)) }
            if let region { items.append(URLQueryItem(name: "region", value: region)) }
            return items.isEmpty ? nil : items
        case .discoverFiltered(let type, let genres, let originCountry, let providers, let watchRegion, let sortBy, let page):
            var items: [URLQueryItem] = [URLQueryItem(name: "type", value: type)]
            if let genres { items.append(URLQueryItem(name: "with_genres", value: genres)) }
            if let originCountry { items.append(URLQueryItem(name: "with_origin_country", value: originCountry)) }
            if let providers { items.append(URLQueryItem(name: "with_watch_providers", value: providers)) }
            if let watchRegion { items.append(URLQueryItem(name: "watch_region", value: watchRegion)) }
            if let sortBy { items.append(URLQueryItem(name: "sort_by", value: sortBy)) }
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items
        case .search(let query, let type, let year):
            var items: [URLQueryItem] = [URLQueryItem(name: "query", value: query)]
            if let type { items.append(URLQueryItem(name: "type", value: type)) }
            if let year { items.append(URLQueryItem(name: "year", value: String(year))) }
            return items
        case .topRated(let type, let page):
            var items: [URLQueryItem] = [URLQueryItem(name: "type", value: type)]
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items
        case .upcoming(let page):
            var items: [URLQueryItem] = []
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items.isEmpty ? nil : items
        case .popular(let type, let page):
            var items: [URLQueryItem] = [URLQueryItem(name: "type", value: type)]
            if let page { items.append(URLQueryItem(name: "page", value: String(page))) }
            return items
        case .genres(let type), .providers(let type):
            return [URLQueryItem(name: "type", value: type)]
        default:
            return nil
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .addToWatchlist(let tmdbId, let mediaType, let status):
            return AddToWatchlistBody(tmdbId: tmdbId, mediaType: mediaType, status: status)
        case .rateMedia(_, _, let rating):
            return RateMediaBody(rating: rating)
        default:
            return nil
        }
    }
}

// MARK: - Request Bodies

private struct AddToWatchlistBody: Encodable {
    let tmdbId: Int
    let mediaType: String
    let status: String
}

private struct RateMediaBody: Encodable {
    let rating: Int
}
