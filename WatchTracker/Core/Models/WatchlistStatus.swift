import Foundation

enum WatchlistStatus: String, Codable, CaseIterable {
    case watching
    case planToWatch = "plan_to_watch"
    case completed

    var displayName: String {
        switch self {
        case .watching:    Strings.Status.watching
        case .planToWatch: Strings.Status.planToWatch
        case .completed:   Strings.Status.completed
        }
    }

    var icon: String {
        switch self {
        case .watching:    "play.circle"
        case .planToWatch: "bookmark"
        case .completed:   "checkmark.seal"
        }
    }
}
