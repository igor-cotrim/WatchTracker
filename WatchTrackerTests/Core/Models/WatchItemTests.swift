import Foundation
import Testing
@testable import WatchTracker

@Suite("WatchItem", .tags(.pure, .model))
struct WatchItemTests {

    private func decode(_ json: String) throws -> WatchItem {
        try APIClient.makeDecoder().decode(WatchItem.self, from: Data(json.utf8))
    }

    private let minimalJSON = """
    {
        "id": 1,
        "user_id": "user-1",
        "tmdb_id": 550,
        "media_type": "movie",
        "status": "watching",
        "added_at": "2026-01-15T12:00:00.123456Z"
    }
    """

    @Test func `decodes with the API date strategy`() throws {
        let item = try decode(minimalJSON)
        #expect(item.id == 1)
        #expect(item.tmdbId == 550)
        #expect(item.mediaType == .movie)
        #expect(item.status == .watching)
        #expect(Int(item.addedAt.timeIntervalSince1970) == 1768478400)
    }

    @Test func `optional display fields default to nil when absent`() throws {
        let item = try decode(minimalJSON)
        #expect(item.title == nil)
        #expect(item.posterPath == nil)
        #expect(item.newEpisodesCount == nil)
        #expect(item.isAnime == nil)
        #expect(item.newSeasonNumber == nil)
    }

    @Test func `posterURL uses the w342 TMDB size`() {
        let item = TestFixtures.watchItem()
        #expect(item.posterURL?.absoluteString == "https://image.tmdb.org/t/p/w342/test.jpg")
    }

    @Test func `posterURL is nil without a poster path`() throws {
        var item = try decode(minimalJSON)
        item.posterPath = nil
        #expect(item.posterURL == nil)
    }

    @Test func `decodes the plan_to_watch status`() throws {
        let item = try decode(minimalJSON.replacingOccurrences(of: "\"watching\"", with: "\"plan_to_watch\""))
        #expect(item.status == .planToWatch)
    }
}
