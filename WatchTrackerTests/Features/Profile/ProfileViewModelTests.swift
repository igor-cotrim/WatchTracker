import Foundation
import Testing
@testable import WatchTracker

@Suite("ProfileViewModel", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
@MainActor
struct ProfileViewModelTests {

    private func makeViewModel() -> (ProfileViewModel, MockProfileService) {
        let service = MockProfileService()
        return (ProfileViewModel(service: service), service)
    }

    @Test func `fetchStats publishes the stats`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .success(TestFixtures.profileStats(episodesWatched: 99))

        await vm.fetchStats()

        #expect(vm.stats?.episodesWatched == 99)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
        #expect(service.fetchStatsCallCount == 1)
    }

    @Test func `failure sets a user-facing message and leaves stats nil`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .failure(MockError.generic("boom"))

        await vm.fetchStats()

        #expect(vm.stats == nil)
        #expect(vm.errorMessage != nil)
        #expect(vm.isLoading == false)
    }

    @Test func `a connection failure uses the friendly connection copy`() async {
        // ProfileViewModel is the one ViewModel using `userFacingMessage` instead of
        // `localizedDescription`, so a dropped connection must not leak URLError text.
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .failure(URLError(.notConnectedToInternet))

        await vm.fetchStats()

        #expect(vm.errorMessage == Strings.Common.connectionError)
    }

    @Test func `a refresh keeps the previous stats visible on failure`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .success(TestFixtures.profileStats(episodesWatched: 42))
        await vm.fetchStats()

        service.fetchStatsResult = .failure(MockError.generic("boom"))
        await vm.fetchStats()

        #expect(vm.stats?.episodesWatched == 42, "Stale data beats an empty screen")
        #expect(vm.errorMessage != nil)
    }

    @Test func `a successful refresh clears the previous error`() async {
        let (vm, service) = makeViewModel()
        service.fetchStatsResult = .failure(MockError.generic("boom"))
        await vm.fetchStats()
        #expect(vm.errorMessage != nil)

        service.fetchStatsResult = .success(TestFixtures.profileStats())
        await vm.fetchStats()
        #expect(vm.errorMessage == nil)
    }

    @Test func `isLoading is false once the fetch settles`() async {
        let (vm, _) = makeViewModel()
        await vm.fetchStats()
        #expect(vm.isLoading == false)
    }

    @Test func `refetching does not re-enter the loading state`() async {
        // `isLoading` only guards the first load; refreshes keep the UI populated.
        let (vm, _) = makeViewModel()
        await vm.fetchStats()
        await vm.fetchStats()
        #expect(vm.isLoading == false)
        #expect(vm.stats != nil)
    }
}
