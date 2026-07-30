import Foundation

/// Whether the current runtime can execute the `@available(iOS 26, *)` AI code paths.
///
/// Swift Testing rejects `@available` on a `@Test` function, so these suites used to
/// open with `guard #available(iOS 26, *) else { return }` — which made every test
/// *pass* on an older simulator without running a single assertion. 26 tests reported
/// green while `AIService` and `AISuggestionsViewModel` sat at 0% coverage.
///
/// Suites now carry `.enabled(if: AIRuntime.isAvailable)` so an older runtime reports
/// them as **skipped** instead. The inner `guard`s stay — Swift's availability checker
/// still needs them to reference iOS 26 types — but they are no longer load-bearing.
///
/// Run these against iOS 26: `PLAN=AI IOS_VERSION=26.2 ./scripts/test.sh`
enum AIRuntime {
    static var isAvailable: Bool {
        if #available(iOS 26, *) { true } else { false }
    }
}
