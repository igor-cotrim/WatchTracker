import SwiftUI

struct ProviderBrowseView: View {
    let provider: StreamingProvider

    @State private var viewModel: BrowseGridViewModel

    init(provider: StreamingProvider) {
        self.provider = provider
        let service = DiscoverService()
        _viewModel = State(initialValue: BrowseGridViewModel { page in
            try await service.discoverFiltered(
                type: .movie,
                providers: String(provider.providerId),
                watchRegion: "BR",
                page: page
            )
        })
    }

    var body: some View {
        BrowseGridView(viewModel: viewModel)
            .navigationTitle(provider.providerName)
    }
}
