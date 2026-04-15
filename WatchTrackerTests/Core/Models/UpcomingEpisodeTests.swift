import Testing
import Foundation
@testable import WatchTracker

@Suite(.tags(.pure, .model))
struct UpcomingEpisodeTests {

    // MARK: - localDaysUntilAir

    @Test(arguments: [0, -1, 1, 7])
    func `localDaysUntilAir returns correct offset for days from today`(offset: Int) {
        let episode = TestFixtures.upcomingEpisodeDaysFromToday(offset)
        #expect(episode.localDaysUntilAir == offset)
    }

    @Test func `localDaysUntilAir returns fallback for invalid date`() {
        let episode = TestFixtures.upcomingEpisode(airDate: "not-a-date", fallbackDays: 3)
        #expect(episode.localDaysUntilAir == 3)
    }

    @Test func `localDaysUntilAir for today is zero`() {
        let episode = TestFixtures.upcomingEpisode(airDate: TestFixtures.todayDateString())
        #expect(episode.localDaysUntilAir == 0)
    }

    @Test func `localDaysUntilAir for yesterday is negative`() {
        let episode = TestFixtures.upcomingEpisode(airDate: TestFixtures.yesterdayDateString())
        #expect(episode.localDaysUntilAir == -1)
    }

    @Test func `localDaysUntilAir for tomorrow is one`() {
        let episode = TestFixtures.upcomingEpisode(airDate: TestFixtures.tomorrowDateString())
        #expect(episode.localDaysUntilAir == 1)
    }

    // MARK: - stillURL

    @Test func `stillURL constructs TMDB w300 URL`() throws {
        let episode = TestFixtures.upcomingEpisode(
            airDate: TestFixtures.todayDateString(),
            stillPath: "/still.jpg"
        )
        let url = try #require(episode.stillURL)
        #expect(url.absoluteString.contains("w300"))
        #expect(url.absoluteString.contains("/still.jpg"))
    }

    @Test func `stillURL is nil when stillPath is nil`() {
        let episode = TestFixtures.upcomingEpisode(airDate: TestFixtures.todayDateString(), stillPath: nil)
        #expect(episode.stillURL == nil)
    }
}
