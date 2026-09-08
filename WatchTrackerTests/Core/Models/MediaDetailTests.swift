import Testing
import Foundation
@testable import WatchTracker

@Suite(.tags(.pure, .model))
struct MediaDetailTests {

    // MARK: - mediaType inference

    @Test func `title only infers movie type`() {
        let detail = TestFixtures.mediaDetail(title: "Inception", name: nil)
        #expect(detail.mediaType == .movie)
    }

    @Test func `name only infers tv type`() {
        let detail = TestFixtures.mediaDetail(title: nil, name: "Breaking Bad")
        #expect(detail.mediaType == .tv)
    }

    @Test func `both title and name infers movie (title wins)`() {
        let detail = TestFixtures.mediaDetail(title: "Movie", name: "Show")
        #expect(detail.mediaType == .movie)
    }

    // MARK: - displayTitle

    @Test func `displayTitle returns title when present`() {
        let detail = TestFixtures.mediaDetail(title: "Inception", name: nil)
        #expect(detail.displayTitle == "Inception")
    }

    @Test func `displayTitle returns name when title is nil`() {
        let detail = TestFixtures.mediaDetail(title: nil, name: "Breaking Bad")
        #expect(detail.displayTitle == "Breaking Bad")
    }

    @Test func `displayTitle returns Unknown when both nil`() {
        let detail = TestFixtures.mediaDetail(title: nil, name: nil)
        #expect(detail.displayTitle == "Unknown")
    }

    // MARK: - releaseYear

    @Test func `releaseYear extracts year from releaseDate`() {
        // mediaDetail() hardcodes release_date "2020-01-15"
        let detail = TestFixtures.mediaDetail()
        #expect(detail.releaseYear == "2020")
    }

    @Test func `releaseYear returns nil for empty date string`() {
        // We can't inject a custom releaseDate via TestFixtures easily,
        // so test using a MediaDetail with nil dates.
        // Build one with no dates using raw JSON.
        let json = """
        {"id":1,"title":"Test","overview":null,"poster_path":null,"backdrop_path":null,
         "release_date":null,"first_air_date":null,"vote_average":null,"genres":null,
         "credits":null,"watch_providers":null,"seasons":null,"watchlist_status":null}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let detail = try! decoder.decode(MediaDetail.self, from: Data(json.utf8))
        #expect(detail.releaseYear == nil)
    }

    @Test func `releaseYear returns nil for short date string`() {
        let json = """
        {"id":1,"title":"Test","overview":null,"poster_path":null,"backdrop_path":null,
         "release_date":"20","first_air_date":null,"vote_average":null,"genres":null,
         "credits":null,"watch_providers":null,"seasons":null,"watchlist_status":null}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let detail = try! decoder.decode(MediaDetail.self, from: Data(json.utf8))
        #expect(detail.releaseYear == nil)
    }

    // MARK: - runtimeMinutes

    @Test func `runtimeMinutes reads runtime for a movie`() {
        let detail = TestFixtures.mediaDetail(runtime: 148)
        #expect(detail.runtimeMinutes == 148)
    }

    @Test func `runtimeMinutes reads the first episodeRunTime for a series`() {
        let detail = TestFixtures.tvDetail(episodeRunTime: [45, 60])
        #expect(detail.runtimeMinutes == 45)
    }

    @Test func `runtimeMinutes ignores episodeRunTime on a movie`() {
        let detail = TestFixtures.mediaDetail(runtime: 148, episodeRunTime: [45])
        #expect(detail.runtimeMinutes == 148)
    }

    @Test func `runtimeMinutes ignores runtime on a series`() {
        let detail = TestFixtures.mediaDetail(
            title: nil,
            name: "Show",
            runtime: 148,
            episodeRunTime: [45]
        )
        #expect(detail.runtimeMinutes == 45)
    }

    // TMDB reports 0 / [] rather than null for titles it has no runtime for.
    @Test func `runtimeMinutes treats a zero movie runtime as absent`() {
        let detail = TestFixtures.mediaDetail(runtime: 0)
        #expect(detail.runtimeMinutes == nil)
    }

    @Test func `runtimeMinutes treats an empty episodeRunTime as absent`() {
        let detail = TestFixtures.tvDetail(episodeRunTime: [])
        #expect(detail.runtimeMinutes == nil)
    }

    @Test func `runtimeMinutes is nil when both fields are missing`() {
        #expect(TestFixtures.mediaDetail().runtimeMinutes == nil)
        #expect(TestFixtures.tvDetail().runtimeMinutes == nil)
    }

    // MARK: - Image URLs

    @Test func `posterURL constructs TMDB w342 URL`() throws {
        let detail = TestFixtures.mediaDetail()
        let url = try #require(detail.posterURL)
        #expect(url.absoluteString.contains("w342"))
        #expect(url.absoluteString.contains("/poster.jpg"))
    }

    @Test func `posterURL is nil when posterPath is nil`() {
        let json = """
        {"id":1,"title":"Test","overview":null,"poster_path":null,"backdrop_path":null,
         "release_date":null,"first_air_date":null,"vote_average":null,"genres":null,
         "credits":null,"watch_providers":null,"seasons":null,"watchlist_status":null}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let detail = try! decoder.decode(MediaDetail.self, from: Data(json.utf8))
        #expect(detail.posterURL == nil)
    }

    @Test func `backdropURL constructs TMDB w780 URL`() throws {
        let detail = TestFixtures.mediaDetail()
        let url = try #require(detail.backdropURL)
        #expect(url.absoluteString.contains("w780"))
        #expect(url.absoluteString.contains("/backdrop.jpg"))
    }

    // MARK: - Trailer

    @Test func `trailer is absent when the backend found no video`() {
        #expect(TestFixtures.mediaDetail().trailer == nil)
    }

    @Test func `trailer builds a youtube app deep link and a web fallback`() throws {
        let detail = TestFixtures.mediaDetail(trailerKey: "dQw4w9WgXcQ")
        let trailer = try #require(detail.trailer)

        #expect(trailer.key == "dQw4w9WgXcQ")
        #expect(try #require(trailer.appURL).absoluteString == "youtube://watch?v=dQw4w9WgXcQ")
        #expect(try #require(trailer.webURL).absoluteString == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    }

    // MARK: - Cast

    @Test func `cast decodes with an optional character name`() throws {
        let detail = TestFixtures.mediaDetail(
            cast: [(name: "Bob Odenkirk", character: "Jimmy McGill"), (name: "Rhea Seehorn", character: nil)]
        )
        let cast = try #require(detail.credits?.cast)

        #expect(cast.count == 2)
        #expect(cast[0].character == "Jimmy McGill")
        #expect(cast[1].character == nil)
        #expect(cast[0].profileURL == nil)
    }

    /// `h632` is deliberate: TMDB only offers w45, w185, h632 and original for profiles,
    /// and w185 is fewer pixels than a 72pt avatar needs on a 3x screen.
    @Test func `profileURL uses the h632 TMDB profile size`() throws {
        let json = Data("""
        {"id":1,"name":"Bob Odenkirk","character":"Jimmy McGill","profile_path":"/face.jpg"}
        """.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let member = try decoder.decode(CastMember.self, from: json)

        #expect(member.profileURL?.absoluteString == "https://image.tmdb.org/t/p/h632/face.jpg")
    }
}
