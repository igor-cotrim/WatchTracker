import Foundation

enum WatchlistStatus: String, Codable, CaseIterable {
    case planToWatch = "plan_to_watch"
    case watching
    case completed

    var displayName: String {
        switch self {
        case .planToWatch: Strings.Status.planToWatch
        case .watching:    Strings.Status.watching
        case .completed:   Strings.Status.completed
        }
    }

    var icon: String {
        switch self {
        case .planToWatch: "bookmark"
        case .watching:    "play.circle"
        case .completed:   "checkmark.seal"
        }
    }
}
