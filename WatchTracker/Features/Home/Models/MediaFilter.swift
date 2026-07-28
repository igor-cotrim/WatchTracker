import Foundation

enum MediaFilter: String, CaseIterable, Identifiable {
    case all
    case movie
    case tv
    case anime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:   Strings.MediaFilter.all
        case .movie: Strings.MediaFilter.movies
        case .tv:    Strings.MediaFilter.tv
        case .anime: Strings.MediaFilter.anime
        }
    }
}
