import Foundation

struct ProfileStats: Codable {
    let episodesWatched: Int
    let moviesWatched: Int
    let showsCompleted: Int
    let titlesRated: Int
    let averageRating: Double

    var averageRatingDisplay: String {
        guard averageRating > 0 else { return Strings.Profile.statsAverageRatingEmpty }
        return (averageRating / 2).formatted(.number.precision(.fractionLength(1)))
    }
}
