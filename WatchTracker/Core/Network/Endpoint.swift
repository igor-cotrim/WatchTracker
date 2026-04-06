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
    case trending
    case search(query: String)
    case nowPlaying

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
        case .discover:
            return "/discover"
        case .trending:
            return "/discover/trending"
        case .search:
            return "/discover/search"
        case .nowPlaying:
            return "/discover/now-playing"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .watchlist, .mediaDetail, .seasonDetail, .discover, .trending, .search, .nowPlaying:
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
        case .search(let query):
            return [URLQueryItem(name: "query", value: query)]
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
