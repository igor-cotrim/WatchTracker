import Auth
import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `Features/Profile/Components/`, all previously at 0%.
///
/// `ProfilePreferencesSection` reads `@AppStorage`, so every view model here gets its own
/// `UserDefaults` suite, torn down afterwards — nothing touches `.standard`.
@MainActor
@Suite("Profile components render", .tags(.view, .pure))
struct ProfileComponentRenderTests {

    private let suiteName = "ProfileComponentRenderTests"

    /// The sections below read the user, mail capability, and notification preferences —
    /// never `stats`, which the two grid components take as a plain parameter instead.
    private func makeVM(
        user: User? = AuthFixtures.user(),
        canSendMail: Bool = true
    ) -> ProfileViewModel {
        ProfileViewModel(
            service: MockProfileService(),
            auth: MockAuthService(currentUser: user),
            notifications: MockNotificationScheduler(),
            defaults: UserDefaults(suiteName: suiteName)!,
            canSendMail: { canSendMail }
        )
    }

    private func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Plain-value components

    @Test(arguments: [true, false])
    func `stats grid renders loaded and loading`(loaded: Bool) {
        let stats = loaded ? TestFixtures.profileStats() : nil
        _ = render(ProfileStatsGrid(stats: stats), height: 400)
    }

    @Test(arguments: [true, false])
    func `stats link renders loaded and loading`(loaded: Bool) {
        let stats = loaded ? TestFixtures.profileStats() : nil
        _ = render(ProfileStatsLink(stats: stats), height: 120)
    }

    @Test func `settings label renders its variants`() {
        for (value, isExternal) in [(nil, false), ("Value", false), (nil, true)] as [(String?, Bool)] {
            _ = render(
                SettingsLabel(
                    title: "Title",
                    systemImage: "gear",
                    tint: .brandPrimary,
                    value: value,
                    isExternal: isExternal
                ),
                height: 60
            )
        }
    }

    @Test func `about section renders`() {
        _ = render(ProfileAboutSection(), height: 200)
    }

    @Test(arguments: [true, false])
    func `account card renders with and without a user`(hasUser: Bool) {
        _ = render(ProfileAccountCard(user: hasUser ? AuthFixtures.user() : nil), height: 160)
    }

    // MARK: - ViewModel-backed sections

    @Test func `account section renders`() {
        defer { tearDown() }
        _ = render(ProfileAccountSection(viewModel: makeVM()), height: 300)
    }

    @Test func `preferences section renders`() {
        defer { tearDown() }
        _ = render(ProfilePreferencesSection(viewModel: makeVM()), height: 300)
    }

    /// The support section hides its mail row when the device cannot send mail, which is
    /// the state a simulator without a Mail account is actually in.
    @Test(arguments: [true, false])
    func `support section renders for either mail capability`(canSendMail: Bool) {
        defer { tearDown() }
        _ = render(ProfileSupportSection(viewModel: makeVM(canSendMail: canSendMail)), height: 300)
    }
}
