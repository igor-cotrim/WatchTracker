import Foundation

/// A load that failed, and how much of the screen that is allowed to cost.
///
/// The two cases exist because of weak connections. A refresh that fails while a cached list
/// is already on screen must not replace that list with a full-screen error — the user can
/// still read, scroll and navigate everything they are looking at; all that is missing is
/// *newer* data. A single `errorMessage` string could not tell those apart, so every screen
/// blanked itself over a failure it had already recovered from.
nonisolated enum LoadFailure: Equatable, Sendable {
    /// There is nothing on screen. The failure owns it, and offers the retry.
    case blocking(String)
    /// Cached content is still on screen. The failure is a line above it, and nothing more.
    case stale(String)

    var message: String {
        switch self {
        case .blocking(let message), .stale(let message): return message
        }
    }

    var isBlocking: Bool {
        if case .blocking = self { return true }
        return false
    }

    /// The case that fits: what the screen already has decides, not what went wrong.
    static func from(_ error: Error, hasContent: Bool) -> LoadFailure {
        hasContent ? .stale(error.userFacingMessage) : .blocking(error.userFacingMessage)
    }
}
