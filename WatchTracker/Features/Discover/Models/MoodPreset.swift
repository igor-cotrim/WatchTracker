import Foundation

struct MoodPreset: Identifiable, Hashable {
    let id: String
    let title: String
    private let movieGenreIds: [Int]
    private let tvGenreIds: [Int]
    let sortBy: String?

    func genreIds(for type: MediaType) -> [Int] {
        type == .movie ? movieGenreIds : tvGenreIds
    }

    func genresQueryValue(for type: MediaType) -> String {
        genreIds(for: type).map(String.init).joined(separator: ",")
    }

    static let all: [MoodPreset] = [
        MoodPreset(
            id: "relax",
            title: Strings.Discover.moodRelax,
            movieGenreIds: [35, 10751],
            tvGenreIds: [35, 10762],
            sortBy: "popularity.desc"
        ),
        MoodPreset(
            id: "adrenaline",
            title: Strings.Discover.moodAdrenaline,
            movieGenreIds: [28, 12, 53],
            tvGenreIds: [10759, 9648],
            sortBy: "popularity.desc"
        ),
        MoodPreset(
            id: "cry",
            title: Strings.Discover.moodCry,
            movieGenreIds: [18, 10749],
            tvGenreIds: [18],
            sortBy: "vote_average.desc"
        ),
        MoodPreset(
            id: "scare",
            title: Strings.Discover.moodScare,
            movieGenreIds: [27, 9648],
            tvGenreIds: [9648],
            sortBy: "popularity.desc"
        ),
        MoodPreset(
            id: "feel_good",
            title: Strings.Discover.moodFeelGood,
            movieGenreIds: [35, 10749],
            tvGenreIds: [35],
            sortBy: "vote_average.desc"
        ),
        MoodPreset(
            id: "heavy",
            title: Strings.Discover.moodHeavy,
            movieGenreIds: [80, 53, 18],
            tvGenreIds: [80, 18],
            sortBy: "vote_average.desc"
        )
    ]
}
