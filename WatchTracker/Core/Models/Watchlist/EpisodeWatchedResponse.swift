import Foundation

/// Response returned by the backend when marking an episode as watched.
/// Contains `statusChanged` when the show's watchlist status was automatically
/// transitioned (e.g. watching → completed after the last episode).
struct EpisodeWatchedResponse: Decodable {
    let statusChanged: WatchlistStatus?
}
