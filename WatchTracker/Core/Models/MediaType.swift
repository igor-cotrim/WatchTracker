import Foundation

enum MediaType: String, Codable, CaseIterable {
    case movie
    case tv
    
    var displayName: String {
        switch self {
        case .movie: Strings.MediaTypeLabel.movie
        case .tv: Strings.MediaTypeLabel.series
        }
    }
}
