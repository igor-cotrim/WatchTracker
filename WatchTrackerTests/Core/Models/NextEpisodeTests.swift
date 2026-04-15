import Testing
@testable import WatchTracker

@Suite(.tags(.pure, .model))
struct NextEpisodeTests {

    // MARK: - displayLabel

    @Test func `displayLabel formats season episode and name`() {
        let ep = TestFixtures.nextEpisode(seasonNumber: 1, episodeNumber: 3, name: "Pilot")
        #expect(ep.displayLabel == "T1 E3 · Pilot")
    }

    @Test func `displayLabel works for double digit season and episode`() {
        let ep = TestFixtures.nextEpisode(seasonNumber: 10, episodeNumber: 22, name: "Finale")
        #expect(ep.displayLabel == "T10 E22 · Finale")
    }

    // MARK: - isReleased

    @Test func `isReleased is true when airDate is nil`() {
        let ep = TestFixtures.nextEpisode(airDate: nil)
        #expect(ep.isReleased == true)
    }

    @Test func `isReleased is true for past date`() {
        let ep = TestFixtures.nextEpisode(airDate: TestFixtures.yesterdayDateString())
        #expect(ep.isReleased == true)
    }

    @Test func `isReleased is true for today`() {
        let ep = TestFixtures.nextEpisode(airDate: TestFixtures.todayDateString())
        #expect(ep.isReleased == true)
    }

    @Test func `isReleased is false for future date`() {
        let ep = TestFixtures.nextEpisode(airDate: TestFixtures.tomorrowDateString())
        #expect(ep.isReleased == false)
    }

    @Test func `isReleased is true for invalid date string`() {
        let ep = TestFixtures.nextEpisode(airDate: "not-a-date")
        #expect(ep.isReleased == true)
    }
}
