import Foundation

@available(iOS 26, *)
struct ResolvedSuggestion: Identifiable {
    let id: Int
    let suggestion: AISuggestionItem
    let media: MediaDetail
    
    init(suggestion: AISuggestionItem, media: MediaDetail) {
        self.id = media.id
        self.suggestion = suggestion
        self.media = media
    }
}
