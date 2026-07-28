import Foundation
import Testing
@testable import WatchTracker

@Suite("Strings.Rating.mood", .tags(.pure))
struct RatingMoodTests {

    private static let awful = String(localized: "rating.mood.awful")
    private static let meh = String(localized: "rating.mood.meh")
    private static let decent = String(localized: "rating.mood.decent")
    private static let great = String(localized: "rating.mood.great")
    private static let masterpiece = String(localized: "rating.mood.masterpiece")

    @Test(arguments: [
        (rating: 1, expected: awful),
        (rating: 2, expected: awful),
        (rating: 3, expected: meh),
        (rating: 4, expected: meh),
        (rating: 5, expected: decent),
        (rating: 6, expected: decent),
        (rating: 7, expected: great),
        (rating: 8, expected: great),
        (rating: 9, expected: masterpiece),
        (rating: 10, expected: masterpiece),
    ])
    func `each rating lands in its bucket`(rating: Int, expected: String) {
        #expect(Strings.Rating.mood(forRating: rating) == expected)
    }

    @Test func `every bucket resolves to real catalog copy`() {
        let buckets = [Self.awful, Self.meh, Self.decent, Self.great, Self.masterpiece]
        for bucket in buckets {
            #expect(!bucket.hasPrefix("rating.mood."), "Missing catalog entry: \(bucket)")
        }
    }

    @Test(arguments: [0, -1, -100])
    func `non-positive ratings fall into the lowest bucket`(rating: Int) {
        #expect(Strings.Rating.mood(forRating: rating) == Strings.Rating.mood(forRating: 2))
    }

    @Test(arguments: [11, 99])
    func `out-of-range ratings fall into the highest bucket`(rating: Int) {
        #expect(Strings.Rating.mood(forRating: rating) == Strings.Rating.mood(forRating: 10))
    }

    @Test func `adjacent buckets produce different copy`() {
        let buckets = [1, 3, 5, 7, 9].map { Strings.Rating.mood(forRating: $0) }
        #expect(Set(buckets).count == 5, "Each bucket must have distinct copy")
    }
}

@Suite("Strings parameterised keys", .tags(.pure))
struct StringsFormattingTests {

    /// A localized string that comes back as its own key means the key is missing
    /// from `Localizable.xcstrings`.
    private func assertResolved(_ value: String, key: String, _ comment: Comment? = nil) {
        #expect(value != key, comment ?? "Missing catalog entry for \(key)")
        #expect(!value.isEmpty)
    }

    @Test func `Card newEpisodes interpolates the count`() {
        let value = Strings.Card.newEpisodes(3)
        assertResolved(value, key: "card.new_episodes")
        #expect(value.contains("3"))
    }

    @Test func `Watching episodeLabel interpolates season and episode`() {
        let value = Strings.Watching.episodeLabel(season: 2, episode: 7)
        assertResolved(value, key: "watching.episode_label")
        #expect(value.contains("2"))
        #expect(value.contains("7"))
    }

    @Test func `Upcoming daysAway interpolates the day count`() {
        let value = Strings.Upcoming.daysAway(5)
        assertResolved(value, key: "upcoming.days_away")
        #expect(value.contains("5"))
    }

    @Test func `Detail seasonEpisodesCount interpolates the count`() {
        let value = Strings.Detail.seasonEpisodesCount(12)
        assertResolved(value, key: "detail.season_episodes_count")
        #expect(value.contains("12"))
    }

    @Test func `Notifications newSeasonBody interpolates the season`() {
        let value = Strings.Notifications.newSeasonBody(season: 4)
        assertResolved(value, key: "notifications.new_season_body")
        #expect(value.contains("4"))
    }

    @Test func `Episode label interpolates number and name`() {
        let value = Strings.Episode.label(number: 3, name: "The Pilot")
        assertResolved(value, key: "episode.label")
        #expect(value.contains("3"))
        #expect(value.contains("The Pilot"))
    }

    @Test func `Discover provider sections interpolate the provider name`() {
        let sections = [
            Strings.Discover.newOnProvider("Netflix"),
            Strings.Discover.topTenOnProvider("Netflix"),
            Strings.Discover.trendingOnProvider("Netflix"),
            Strings.Discover.acclaimedOnProvider("Netflix"),
        ]
        for section in sections {
            #expect(section.contains("Netflix"))
        }
        #expect(Set(sections).count == 4, "Each provider section needs distinct copy")
    }

    @Test func `Discover topTenRank interpolates rank and title`() {
        let value = Strings.Discover.topTenRank(1, title: "Dune")
        #expect(value.contains("1"))
        #expect(value.contains("Dune"))
    }

    @Test func `Feedback subject interpolates the app name`() {
        let value = Strings.Feedback.subject(appName: "WatchTracker")
        assertResolved(value, key: "feedback.subject")
        #expect(value.contains("WatchTracker"))
    }
}
