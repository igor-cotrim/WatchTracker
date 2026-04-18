import SwiftUI

struct MoodBrowseView: View {
    let mood: MoodPreset

    @State private var viewModel: BrowseGridViewModel

    init(mood: MoodPreset) {
        self.mood = mood
        let service = DiscoverService()
        let movieGenres = mood.genresQueryValue(for: .movie)
        let tvGenres = mood.genresQueryValue(for: .tv)
        let sortBy = mood.sortBy
        _viewModel = State(initialValue: BrowseGridViewModel { page in
            async let moviesTask = service.discoverFiltered(
                type: .movie,
                genres: movieGenres,
                sortBy: sortBy,
                page: page
            )
            async let tvTask = service.discoverFiltered(
                type: .tv,
                genres: tvGenres,
                sortBy: sortBy,
                page: page
            )
            let movies = try await moviesTask
            let tv = try await tvTask
            return Self.interleaved(movies, tv)
        })
    }

    var body: some View {
        BrowseGridView(viewModel: viewModel)
            .navigationTitle(mood.title)
    }

    private static func interleaved(_ a: [MediaDetail], _ b: [MediaDetail]) -> [MediaDetail] {
        var result: [MediaDetail] = []
        let maxCount = max(a.count, b.count)
        result.reserveCapacity(a.count + b.count)
        for i in 0..<maxCount {
            if i < a.count { result.append(a[i]) }
            if i < b.count { result.append(b[i]) }
        }
        return result
    }
}
