import Foundation
import Testing
@testable import WatchTracker

@Suite("NotificationService planning helpers", .tags(.pure, .service))
struct NotificationPlanningTests {

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    // MARK: airDate parsing

    @Test func `parses a TMDB calendar date`() throws {
        let date = try #require(NotificationService.airDate(from: "2026-04-15", calendar: Self.utc))
        let components = Self.utc.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 4)
        #expect(components.day == 15)
    }

    @Test(arguments: ["", "15/04/2026", "2026-13-45", "tomorrow"])
    func `rejects malformed dates`(input: String) {
        #expect(NotificationService.airDate(from: input, calendar: Self.utc) == nil)
    }

    @Test func `parses under a non-Gregorian device calendar`() {
        // Regression: without the POSIX locale a Buddhist/Japanese calendar reinterprets
        // the year and the parse silently fails, dropping every episode reminder.
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = TimeZone(identifier: "UTC")!
        #expect(NotificationService.airDate(from: "2026-04-15", calendar: buddhist) != nil)
    }

    // MARK: Trigger components

    @Test func `reminders fire at 20 00 on the air date`() throws {
        let date = try #require(NotificationService.airDate(from: "2026-04-15", calendar: Self.utc))
        let components = NotificationService.triggerComponents(for: date, calendar: Self.utc)

        #expect(components.year == 2026)
        #expect(components.month == 4)
        #expect(components.day == 15)
        #expect(components.hour == 20)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    // MARK: Identifiers

    @Test func `episode identifiers carry the cancellable prefix`() {
        let id = NotificationService.episodeIdentifier(tmdbId: 1399, season: 2, episode: 7)
        #expect(id == "episode-1399-S2E7")
        // `cancelAllEpisodeNotifications` removes by this prefix.
        #expect(id.hasPrefix(NotificationService.episodePrefix))
    }

    @Test func `new-season identifiers do not collide with episode ones`() {
        let seasonId = NotificationService.newSeasonIdentifier(tmdbId: 1399, season: 2)
        #expect(seasonId == "newseason-1399-S2")
        #expect(!seasonId.hasPrefix(NotificationService.episodePrefix))
    }

    @Test func `dedupe keys are unique per show and season`() {
        let a = NotificationService.newSeasonDedupeKey(tmdbId: 1, season: 2)
        let b = NotificationService.newSeasonDedupeKey(tmdbId: 1, season: 3)
        let c = NotificationService.newSeasonDedupeKey(tmdbId: 2, season: 2)
        #expect(Set([a, b, c]).count == 3)
    }
}
