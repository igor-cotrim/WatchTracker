import SwiftUI
import Testing
@testable import WatchTracker

/// Renders `AISuggestionsView`, which is `@available(iOS 26, *)` and therefore cannot be
/// reached from the Unit plan's iOS 18 runtime. Lives in the AI plan instead:
///
///     PLAN=AI IOS_VERSION=26.2 ./scripts/test.sh
///
/// `.enabled(if:)` rather than an early `return`, so an older runtime reports this as
/// skipped instead of passing without having rendered anything.
@MainActor
@Suite(
    "AI screen renders",
    .tags(.view, .pure),
    .enabled(if: AIRuntime.isAvailable, "requires an iOS 26 runtime")
)
struct AIScreenRenderTests {

    @Test func `suggestions screen renders`() {
        guard #available(iOS 26, *) else { return }
        _ = render(AISuggestionsView())
    }
}
