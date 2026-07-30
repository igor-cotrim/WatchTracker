import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `Features/AI/Components/`, both previously at 0%.
///
/// Neither component is gated on iOS 26 — `AIModelAvailability` is a plain enum — so
/// unlike the AI view model these run on the floor runtime too.
@MainActor
@Suite("AI components render", .tags(.view, .pure))
struct AIComponentRenderTests {

    @Test func `suggestion card renders`() {
        let media = TestFixtures.mediaDetail(posterPath: nil, backdropPath: nil)
        _ = render(
            AISuggestionCard(media: media, reason: "Because you liked Fight Club"),
            height: 200
        )
    }

    @Test func `suggestion card renders an empty reason`() {
        let media = TestFixtures.mediaDetail(posterPath: nil, backdropPath: nil)
        _ = render(AISuggestionCard(media: media, reason: ""), height: 200)
    }

    /// Every unavailable state has its own copy and icon, and these are what most users
    /// see — on-device models are unavailable on the majority of installed hardware.
    @Test(arguments: [
        AIModelAvailability.available,
        .notEligible,
        .notEnabled,
        .notReady
    ])
    func `unavailable view renders every availability`(availability: AIModelAvailability) {
        _ = render(AIUnavailableView(availability: availability), height: 300)
    }
}
