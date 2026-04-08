import Foundation

enum WatchlistStatus: String, Codable, CaseIterable {
    case planToWatch = "plan_to_watch"
    case watching
    case completed
    case dropped

    var displayName: String {
        switch self {
        case .planToWatch: "Quero Assistir"
        case .watching: "Assistindo"
        case .completed: "Completo"
        case .dropped: "Abandonado"
        }
    }

    var icon: String {
        switch self {
        case .planToWatch: "bookmark"
        case .watching: "play.circle"
        case .completed: "checkmark.seal"
        case .dropped: "xmark.circle"
        }
    }
}
