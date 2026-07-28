import Foundation
import SwiftUI
import Testing
@testable import WatchTracker

@Suite("WatchlistStatus", .tags(.pure, .model))
struct WatchlistStatusTests {

    @Test func `raw values match the backend contract`() {
        #expect(WatchlistStatus.watching.rawValue == "watching")
        #expect(WatchlistStatus.completed.rawValue == "completed")
        // The only status whose raw value differs from its case name.
        #expect(WatchlistStatus.planToWatch.rawValue == "plan_to_watch")
    }

    @Test func `allCases covers every status`() {
        #expect(WatchlistStatus.allCases.count == 3)
    }

    @Test(arguments: WatchlistStatus.allCases)
    func `round-trips through Codable`(status: WatchlistStatus) throws {
        let data = try JSONEncoder().encode([status])
        let decoded = try JSONDecoder().decode([WatchlistStatus].self, from: data)
        #expect(decoded == [status])
    }

    @Test(arguments: WatchlistStatus.allCases)
    func `has a display name and an icon`(status: WatchlistStatus) {
        #expect(!status.displayName.isEmpty)
        #expect(!status.icon.isEmpty)
    }
}

@Suite("MediaType", .tags(.pure, .model))
struct MediaTypeTests {

    @Test func `raw values match TMDB`() {
        #expect(MediaType.movie.rawValue == "movie")
        #expect(MediaType.tv.rawValue == "tv")
    }

    @Test(arguments: [MediaType.movie, .tv])
    func `has a display name`(type: MediaType) {
        #expect(!type.displayName.isEmpty)
    }
}

@Suite("AppAppearance", .tags(.pure, .model))
struct AppAppearanceTests {

    @Test func `system defers to the OS colour scheme`() {
        #expect(AppAppearance.system.colorScheme == nil)
    }

    @Test func `light and dark map to explicit colour schemes`() {
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test func `storage key is stable`() {
        // Persisted via @AppStorage — renaming this silently resets user preferences.
        #expect(AppAppearance.storageKey == "appAppearance")
    }

    @Test(arguments: AppAppearance.allCases)
    func `id matches the raw value and has a title and icon`(appearance: AppAppearance) {
        #expect(appearance.id == appearance.rawValue)
        #expect(!appearance.title.isEmpty)
        #expect(!appearance.icon.isEmpty)
    }
}

@Suite("StreamingProvider", .tags(.pure, .model))
struct StreamingProviderTests {

    @Test func `id mirrors providerId`() {
        let provider = TestFixtures.streamingProvider(providerId: 337)
        #expect(provider.id == 337)
    }

    @Test func `logoURL uses the w92 TMDB size`() {
        let provider = TestFixtures.streamingProvider(logoPath: "/logo.png")
        #expect(provider.logoURL?.absoluteString == "https://image.tmdb.org/t/p/w92/logo.png")
    }
}

@Suite("ProfileStats", .tags(.pure, .model))
struct ProfileStatsTests {

    @Test func `halves the ten-point average onto the five-star scale`() {
        // The backend stores 1–10; the UI shows 0.5–5.0.
        let stats = TestFixtures.profileStats(averageRating: 7.6)
        #expect(stats.averageRatingDisplay.contains("3"))
        #expect(stats.averageRatingDisplay.contains("8"))
    }

    @Test(arguments: [0.0, -1.0])
    func `shows the empty placeholder when there is no average`(average: Double) {
        let stats = TestFixtures.profileStats(averageRating: average)
        #expect(stats.averageRatingDisplay == Strings.Profile.statsAverageRatingEmpty)
    }

    @Test func `rounds to a single fraction digit`() {
        let stats = TestFixtures.profileStats(averageRating: 9.99)
        // 9.99 / 2 = 4.995 → one fraction digit
        let digits = stats.averageRatingDisplay.filter(\.isNumber)
        #expect(digits.count == 2)
    }
}

@Suite("Import models", .tags(.pure, .model))
struct ImportModelsTests {

    @Test func `ImportItem encodes to snake_case`() throws {
        let item = TestFixtures.importItem(title: "Dune", year: 2021, status: .completed, rating: 9, watchedDate: "2026-01-01")
        let data = try APIClient.makeEncoder().encode(item)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["title"] as? String == "Dune")
        #expect(json["year"] as? Int == 2021)
        #expect(json["status"] as? String == "completed")
        #expect(json["rating"] as? Int == 9)
        #expect(json["watched_date"] as? String == "2026-01-01")
    }

    @Test func `ImportItem omits nil fields`() throws {
        let item = TestFixtures.importItem(year: nil, status: nil, rating: nil, watchedDate: nil)
        let data = try APIClient.makeEncoder().encode(item)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["year"] == nil)
        #expect(json["rating"] == nil)
    }

    @Test func `ImportBatchResult decodes nested counts`() {
        let result = TestFixtures.importBatchResult(
            total: 10, matched: 8, watchlist: 6, ratings: 2,
            unmatched: [("Unknown Film", 1999), ("No Year", nil)]
        )
        #expect(result.total == 10)
        #expect(result.matched == 8)
        #expect(result.imported.watchlist == 6)
        #expect(result.imported.ratings == 2)
        #expect(result.unmatched.count == 2)
        #expect(result.unmatched.first?.title == "Unknown Film")
        #expect(result.unmatched.last?.year == nil)
    }
}
