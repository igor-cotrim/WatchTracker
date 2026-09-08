import Foundation

/// A cast member's page: who they are, plus the filmography the backend curated for them.
/// TMDB's raw `combined_credits` is deduped, stripped of talk-show appearances and ordered
/// by reach server-side, so there is nothing left to filter here.
struct PersonDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let biography: String?
    let profilePath: String?
    let knownForDepartment: String?
    let birthday: String?
    let placeOfBirth: String?
    let credits: [PersonCredit]

    /// `h632` for the same reason as `CastMember.profileURL`: the header portrait is far
    /// larger than the carousel avatar, and `w185` is TMDB's next size down.
    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/h632\(profilePath)")
    }

    /// The bio TMDB returns for a locale it has no translation for is an empty string,
    /// not a missing key — so the view has to treat both as "no biography".
    var displayBiography: String? {
        guard let biography, !biography.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return biography
    }
}

/// One title a person appears in. Carries `mediaType` explicitly rather than inferring it
/// from which of `title`/`name` is set, because the API states it.
struct PersonCredit: Codable, Identifiable {
    let creditId: String
    let tmdbId: Int
    let mediaType: MediaType
    let title: String?
    let name: String?
    let character: String?
    let posterPath: String?
    let releaseDate: String?
    let firstAirDate: String?

    /// A person can be credited twice for the same title, so the *credit* is the identity
    /// here — using the TMDB id would collide inside a `ForEach`.
    var id: String { creditId }

    enum CodingKeys: String, CodingKey {
        case creditId
        case tmdbId = "id"
        case mediaType
        case title
        case name
        case character
        case posterPath
        case releaseDate
        case firstAirDate
    }

    var displayTitle: String {
        title ?? name ?? ""
    }

    var releaseYear: String? {
        let date = releaseDate ?? firstAirDate
        guard let date, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)")
    }
}
