import Foundation
import Testing
@testable import WatchTracker

@Suite("ContinueWatchingItem", .tags(.pure, .model))
struct ContinueWatchingItemTests {

    @Test func `id and tmdbId are distinct fields`() {
        let item = TestFixtures.continueWatchingItem(id: 5, tmdbId: 550)
        #expect(item.id == 5)
        #expect(item.tmdbId == 550)
    }

    @Test func `posterURL is nil without a poster path`() {
        #expect(TestFixtures.continueWatchingItem().posterURL == nil)
    }

    @Test func `stillURL comes from the next episode`() {
        let item = TestFixtures.continueWatchingItem(
            nextEpisode: TestFixtures.nextEpisode(stillPath: "/still.jpg")
        )
        #expect(item.stillURL?.absoluteString == "https://image.tmdb.org/t/p/w300/still.jpg")
    }

    @Test func `stillURL is nil when there is no next episode`() {
        #expect(TestFixtures.continueWatchingItem(nextEpisode: nil).stillURL == nil)
    }

    @Test func `stillURL is nil when the next episode has no still`() {
        let item = TestFixtures.continueWatchingItem(nextEpisode: TestFixtures.nextEpisode(stillPath: nil))
        #expect(item.stillURL == nil)
    }
}

@Suite("UpcomingItem", .tags(.pure, .model))
struct UpcomingItemTests {

    @Test func `id mirrors tmdbId`() {
        #expect(TestFixtures.upcomingItem(tmdbId: 1399).id == 1399)
    }

    @Test func `posterURL is nil without a poster path`() {
        #expect(TestFixtures.upcomingItem().posterURL == nil)
    }

    @Test func `decodes watch providers`() {
        let item = TestFixtures.upcomingItem(watchProviders: ["Netflix", "Max"])
        #expect(item.watchProviders == ["Netflix", "Max"])
    }

    @Test func `stillURL uses the w300 TMDB size`() {
        let episode = TestFixtures.upcomingEpisode(airDate: "2026-01-01", stillPath: "/ep.jpg")
        #expect(episode.stillURL?.absoluteString == "https://image.tmdb.org/t/p/w300/ep.jpg")
    }
}
