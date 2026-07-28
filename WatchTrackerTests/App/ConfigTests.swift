import Foundation
import Testing
@testable import WatchTracker

/// Guards the xcconfig → Info.plist → `Config` seam. The test target sets
/// `TEST_HOST`, so `Bundle.main` resolves to the app bundle and the injected
/// keys are readable exactly as they are at runtime.
///
/// These would have caught the `//`-is-a-comment trap in `.xcconfig`, which
/// silently truncates `https://host` to `https:`.
@Suite("Config", .tags(.pure))
@MainActor
struct ConfigTests {

    @Test(arguments: [
        Config.supabaseURL,
        Config.apiBaseURL,
        Config.privacyPolicyURL,
        Config.tmdbURL,
        Config.reviewURL,
    ])
    func `every configured URL has a scheme and a host`(url: URL) {
        #expect(url.scheme == "https" || url.scheme == "http", "Bad scheme in \(url)")
        #expect(url.host()?.isEmpty == false, "Missing host in \(url) — check the $() slash escaping")
    }

    @Test func `string values are non-empty`() {
        #expect(!Config.supabasePublishableKey.isEmpty)
        #expect(!Config.posthogAPIKey.isEmpty)
        #expect(!Config.posthogHost.isEmpty)
        #expect(!Config.appStoreID.isEmpty)
        #expect(!Config.supportEmail.isEmpty)
    }

    @Test func `no value is left as an unexpanded build setting`() {
        let values = [
            Config.supabaseURL.absoluteString,
            Config.apiBaseURL.absoluteString,
            Config.supabasePublishableKey,
            Config.posthogAPIKey,
            Config.posthogHost,
            Config.appStoreID,
            Config.supportEmail,
        ]
        for value in values {
            #expect(!value.contains("$("), "Unexpanded build setting: \(value)")
        }
    }

    @Test func `supabase key is publishable, never the service_role secret`() {
        #expect(Config.supabasePublishableKey.hasPrefix("sb_publishable_"))
    }

    @Test func `posthog key matches the prefix AnalyticsService guards on`() {
        #expect(Config.posthogAPIKey.hasPrefix("phc_"))
    }

    @Test func `reviewURL is derived from the configured App Store ID`() {
        #expect(Config.reviewURL.absoluteString.contains(Config.appStoreID))
    }
}
