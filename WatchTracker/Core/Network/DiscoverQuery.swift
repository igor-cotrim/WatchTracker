import Foundation

/// The TMDB discover parameters as one value.
///
/// These used to be twelve positional arguments threaded through `Endpoint`,
/// `DiscoverServiceProtocol` and every call site — a shape where `nil, nil, "BR", nil`
/// says nothing about which filter is which. Carrying them together also puts the
/// query-item mapping next to the fields it maps, instead of inside `Endpoint`'s switch.
///
/// Only `type` is required: TMDB scopes a discover call to movies or shows, never both.
struct DiscoverQuery: Hashable, Sendable {
    var type: MediaType
    /// Comma-separated TMDB genre ids. Comma is AND in TMDB, so two genres mean titles
    /// carrying both — which is what a "narrow this down" filter should do.
    var genres: String?
    var originCountry: String?
    var providers: String?
    var watchRegion: String?
    var sortBy: String?
    var page: Int?
    var releaseDateGte: String?
    var releaseDateLte: String?
    var firstAirDateGte: String?
    var firstAirDateLte: String?
    /// A floor on the vote count. Sorting by rating without one surfaces obscure titles
    /// riding a handful of perfect scores, so every rating sort sets it.
    var voteCountGte: Int?

    init(
        type: MediaType,
        genres: String? = nil,
        originCountry: String? = nil,
        providers: String? = nil,
        watchRegion: String? = nil,
        sortBy: String? = nil,
        page: Int? = nil,
        releaseDateGte: String? = nil,
        releaseDateLte: String? = nil,
        firstAirDateGte: String? = nil,
        firstAirDateLte: String? = nil,
        voteCountGte: Int? = nil
    ) {
        self.type = type
        self.genres = genres
        self.originCountry = originCountry
        self.providers = providers
        self.watchRegion = watchRegion
        self.sortBy = sortBy
        self.page = page
        self.releaseDateGte = releaseDateGte
        self.releaseDateLte = releaseDateLte
        self.firstAirDateGte = firstAirDateGte
        self.firstAirDateLte = firstAirDateLte
        self.voteCountGte = voteCountGte
    }

    /// `type` is always sent; every other filter is dropped when absent so the backend
    /// never sees an empty-string parameter it would forward to TMDB.
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "type", value: type.rawValue)]
        append(&items, "with_genres", genres)
        append(&items, "with_origin_country", originCountry)
        append(&items, "with_watch_providers", providers)
        append(&items, "watch_region", watchRegion)
        append(&items, "sort_by", sortBy)
        append(&items, "page", page.map(String.init))
        append(&items, "primary_release_date.gte", releaseDateGte)
        append(&items, "primary_release_date.lte", releaseDateLte)
        append(&items, "first_air_date.gte", firstAirDateGte)
        append(&items, "first_air_date.lte", firstAirDateLte)
        append(&items, "vote_count.gte", voteCountGte.map(String.init))
        return items
    }

    private func append(_ items: inout [URLQueryItem], _ name: String, _ value: String?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: value))
    }
}
