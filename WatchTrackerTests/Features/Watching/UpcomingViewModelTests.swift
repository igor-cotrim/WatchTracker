import Testing
import Foundation
@testable import WatchTracker

@Suite(.tags(.viewModel))
@MainActor
struct UpcomingViewModelTests {

    /// Thursday, 15 January 2026, 12:00 UTC.
    private static let referenceDate = Date(timeIntervalSince1970: 1_768_478_400)

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    private func makeViewModel(
        service: MockWatchlistService? = nil,
        notifications: MockNotificationScheduler? = nil,
        pinned: Bool = false
    ) -> UpcomingViewModel {
        let reference = Self.referenceDate
        let now: @Sendable () -> Date
        if pinned {
            now = { reference }
        } else {
            now = { Date() }
        }
        return UpcomingViewModel(
            service: service ?? MockWatchlistService(),
            notifications: notifications ?? MockNotificationScheduler(),
            calendar: pinned ? Self.utcCalendar : .current,
            now: now
        )
    }

    // MARK: - groupedItems section keys

    @Test(arguments: [
        (-5, "today"),
        (-1, "today"),
        (0, "today"),
        (1, "tomorrow"),
        (7, "later"),
        (100, "later"),
    ])
    func `groupedItems places item in correct section`(offset: Int, expectedSection: String) throws {
        let vm = makeViewModel()
        vm.items = [TestFixtures.upcomingItem(nextEpisodeDaysFromToday: offset)]
        let sectionKey = try #require(vm.groupedItems.first?.sectionKey)
        #expect(sectionKey == expectedSection)
    }

    @Test func `groupedItems day 2 through 6 map to weekday names`() {
        let vm = makeViewModel()
        for offset in 2...6 {
            vm.items = [TestFixtures.upcomingItem(nextEpisodeDaysFromToday: offset)]
            let key = vm.groupedItems.first?.sectionKey ?? ""
            #expect(!["today", "tomorrow", "later"].contains(key))
            #expect(key.isEmpty == false)
        }
    }

    @Test func `groupedItems groups multiple items in same section`() {
        let vm = makeViewModel()
        vm.items = [
            TestFixtures.upcomingItem(tmdbId: 1, nextEpisodeDaysFromToday: 0),
            TestFixtures.upcomingItem(tmdbId: 2, nextEpisodeDaysFromToday: 0),
        ]
        #expect(vm.groupedItems.first { $0.sectionKey == "today" }?.items.count == 2)
    }

    @Test func `groupedItems orders sections today before tomorrow before later`() {
        let vm = makeViewModel()
        vm.items = [
            TestFixtures.upcomingItem(tmdbId: 1, nextEpisodeDaysFromToday: 7),   // later
            TestFixtures.upcomingItem(tmdbId: 2, nextEpisodeDaysFromToday: 0),   // today
            TestFixtures.upcomingItem(tmdbId: 3, nextEpisodeDaysFromToday: 1),   // tomorrow
        ]
        let keys = vm.groupedItems.map(\.sectionKey)
        #expect(keys == ["today", "tomorrow", "later"])
    }

    @Test func `groupedItems puts weekday sections between tomorrow and later`() {
        let vm = makeViewModel()
        vm.items = [
            TestFixtures.upcomingItem(tmdbId: 1, nextEpisodeDaysFromToday: 10),
            TestFixtures.upcomingItem(tmdbId: 2, nextEpisodeDaysFromToday: 3),
            TestFixtures.upcomingItem(tmdbId: 3, nextEpisodeDaysFromToday: 1),
        ]
        let keys = vm.groupedItems.map(\.sectionKey)
        #expect(keys.first == "tomorrow")
        #expect(keys.last == "later")
        #expect(keys.count == 3)
    }

    @Test func `groupedItems omits empty sections`() {
        let vm = makeViewModel()
        vm.items = [TestFixtures.upcomingItem(nextEpisodeDaysFromToday: 0)]
        #expect(vm.groupedItems.allSatisfy { !$0.items.isEmpty })
    }

    @Test func `groupedItems is empty when items is empty`() {
        let vm = makeViewModel()
        vm.items = []
        #expect(vm.groupedItems.isEmpty)
    }

    // MARK: - Deterministic weekday naming

    @Test(arguments: [
        (offset: 2, weekday: "saturday"),
        (offset: 3, weekday: "sunday"),
        (offset: 4, weekday: "monday"),
        (offset: 5, weekday: "tuesday"),
        (offset: 6, weekday: "wednesday"),
    ])
    func `sectionKey names the weekday relative to the injected today`(offset: Int, weekday: String) {
        // Reference date is a Thursday, so +2 is Saturday. Pinning the calendar keeps
        // this independent of the machine's timezone and locale.
        let vm = makeViewModel(pinned: true)
        #expect(vm.sectionKey(for: offset) == weekday)
    }

    @Test func `dayName is lowercased`() {
        let vm = makeViewModel(pinned: true)
        #expect(vm.dayName(offset: 2) == vm.dayName(offset: 2).lowercased())
    }

    @Test(arguments: [-3, 0])
    func `sectionKey treats today and the past as today`(offset: Int) {
        #expect(makeViewModel(pinned: true).sectionKey(for: offset) == "today")
    }

    @Test(arguments: [7, 30])
    func `sectionKey treats a week out or more as later`(offset: Int) {
        #expect(makeViewModel(pinned: true).sectionKey(for: offset) == "later")
    }

    // MARK: - fetch (async)

    @Suite(.tags(.viewModel, .async), .timeLimit(.minutes(1)))
    @MainActor
    struct FetchTests {

        private func makeViewModel(
            _ service: MockWatchlistService
        ) -> (UpcomingViewModel, MockNotificationScheduler) {
            let notifications = MockNotificationScheduler()
            return (UpcomingViewModel(service: service, notifications: notifications), notifications)
        }

        @Test func `fetch populates items on success`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .success([TestFixtures.upcomingItem(nextEpisodeDaysFromToday: 1)])
            let (vm, _) = makeViewModel(mock)

            await vm.fetch()

            #expect(vm.items.count == 1)
            #expect(vm.errorMessage == nil)
        }

        @Test func `fetch sets errorMessage on failure`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .failure(MockError.generic("error"))
            let (vm, _) = makeViewModel(mock)

            await vm.fetch()

            #expect(vm.errorMessage != nil)
            #expect(vm.items.isEmpty)
        }

        @Test func `isLoading is false after fetch`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .success([])
            let (vm, _) = makeViewModel(mock)

            await vm.fetch()

            #expect(vm.isLoading == false)
        }

        @Test func `fetch schedules notifications for the fetched items`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .success([
                TestFixtures.upcomingItem(tmdbId: 1, nextEpisodeDaysFromToday: 1),
                TestFixtures.upcomingItem(tmdbId: 2, nextEpisodeDaysFromToday: 3),
            ])
            let (vm, notifications) = makeViewModel(mock)

            await vm.fetch()

            #expect(notifications.scheduled.count == 1)
            #expect(notifications.scheduled.first?.map(\.tmdbId) == [1, 2])
        }

        @Test func `a failed fetch does not schedule notifications`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .failure(MockError.generic("error"))
            let (vm, notifications) = makeViewModel(mock)

            await vm.fetch()

            #expect(notifications.scheduled.isEmpty)
        }

        @Test func `a successful refetch clears the previous error`() async {
            let mock = MockWatchlistService()
            mock.fetchUpcomingResult = .failure(MockError.generic("error"))
            let (vm, _) = makeViewModel(mock)
            await vm.fetch()
            #expect(vm.errorMessage != nil)

            mock.fetchUpcomingResult = .success([])
            await vm.fetch()
            #expect(vm.errorMessage == nil)
        }
    }
}
