import Testing
import Foundation
@testable import WatchTracker

@MainActor
@Suite("AppStartup", .tags(.async), .timeLimit(.minutes(1)))
struct AppStartupTests {

    /// Each run gets its own `UserDefaults` suite so the one-shot permission flag from one
    /// test can never leak into another (or into the developer's real preferences).
    private final class Harness {
        let service = MockWatchlistService()
        let notifications = MockNotificationScheduler()
        let defaults: UserDefaults
        let startup: AppStartup
        private let suiteName: String

        init() {
            suiteName = "test-\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName)!
            startup = AppStartup(
                service: service,
                notifications: notifications,
                defaults: defaults
            )
        }

        var hasRequestedPermission: Bool {
            defaults.bool(forKey: NotificationService.hasRequestedAuthorizationKey)
        }

        var remindersEnabled: Bool {
            defaults.bool(forKey: NotificationService.episodeRemindersEnabledKey)
        }

        deinit { defaults.removePersistentDomain(forName: suiteName) }
    }

    private func makeHarness() -> Harness { Harness() }

    // MARK: - Permission prompt

    @Test func `the first run asks for authorization once and records the flag`() async {
        let harness = makeHarness()

        await harness.startup.run()

        #expect(harness.notifications.authorizationRequestCount == 1)
        #expect(harness.hasRequestedPermission)
    }

    @Test func `granting permission turns episode reminders on`() async {
        let harness = makeHarness()
        harness.notifications.authorizationResult = true

        await harness.startup.run()

        #expect(harness.remindersEnabled)
    }

    @Test func `denying permission leaves episode reminders off`() async {
        let harness = makeHarness()
        harness.notifications.authorizationResult = false

        await harness.startup.run()

        #expect(harness.remindersEnabled == false)
        #expect(harness.hasRequestedPermission, "The flag is set either way — iOS only prompts once")
    }

    @Test func `a second run does not prompt again`() async {
        // Re-prompting is impossible on iOS anyway, but re-running the branch would
        // silently re-enable reminders the user had just turned off in Profile.
        let harness = makeHarness()
        await harness.startup.run()

        harness.notifications.authorizationResult = true
        harness.defaults.set(false, forKey: NotificationService.episodeRemindersEnabledKey)
        await harness.startup.run()

        #expect(harness.notifications.authorizationRequestCount == 1)
        #expect(harness.remindersEnabled == false)
    }

    // MARK: - Scheduling

    @Test func `upcoming items reach the scheduler`() async {
        let harness = makeHarness()
        let items = [
            TestFixtures.upcomingItem(tmdbId: 1, title: "Severance"),
            TestFixtures.upcomingItem(tmdbId: 2, title: "Andor"),
        ]
        harness.service.fetchUpcomingResult = .success(items)

        await harness.startup.run()

        #expect(harness.service.fetchUpcomingCallCount == 1)
        #expect(harness.notifications.scheduled.count == 1)
        #expect(harness.notifications.scheduled.first?.map(\.tmdbId) == [1, 2])
    }

    @Test func `a failed fetch schedules nothing`() async {
        let harness = makeHarness()
        harness.service.fetchUpcomingResult = .failure(MockError.generic("offline"))

        await harness.startup.run()

        #expect(harness.notifications.scheduled.isEmpty)
    }

    @Test func `an empty upcoming list still refreshes the schedule`() async {
        // Scheduling with zero items is how stale reminders get cleared, so the call must happen.
        let harness = makeHarness()
        harness.service.fetchUpcomingResult = .success([])

        await harness.startup.run()

        #expect(harness.notifications.scheduled.count == 1)
        #expect(harness.notifications.scheduled.first?.isEmpty == true)
    }
}
