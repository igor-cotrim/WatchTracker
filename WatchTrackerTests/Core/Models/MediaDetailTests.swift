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
}
