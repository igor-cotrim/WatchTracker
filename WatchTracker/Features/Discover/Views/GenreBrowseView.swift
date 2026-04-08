import SwiftUI

struct GenreBrowseView: View {
    let genre: Genre

    @State private var viewModel: BrowseGridViewModel

    init(genre: Genre) {
        self.genre = genre
        let service = DiscoverService()
        _viewModel = State(initialValue: BrowseGridViewModel { page in
            try await service.discoverFiltered(type: .movie, genres: String(genre.id), page: page)
        })
    }

    var body: some View {
        BrowseGridView(viewModel: viewModel)
            .navigationTitle(genre.name)
    }
}
