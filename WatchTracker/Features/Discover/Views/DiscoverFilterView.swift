import SwiftUI

/// The filter sheet Discover opens. It never queries anything itself: committing hands the
/// finished `DiscoverFilter` back through `onApply`, and the caller navigates to the grid.
struct DiscoverFilterView: View {
    let initialFilter: DiscoverFilter
    let onApply: (DiscoverFilter) -> Void

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DiscoverFilterViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    form(viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(Strings.DiscoverFilter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.DiscoverFilter.clear) {
                        viewModel?.clearAll()
                    }
                    .disabled(viewModel?.draft.activeCriteriaCount == 0)
                }
            }
        }
        .task {
            let viewModel = viewModel ?? container.makeDiscoverFilterViewModel(initialFilter: initialFilter)
            self.viewModel = viewModel
            await viewModel.load()
        }
    }

    // MARK: - Sections

    private func form(_ viewModel: DiscoverFilterViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section(Strings.DiscoverFilter.sectionType) {
                    chipRow(DiscoverType.allCases) { type in
                        FilterChip(title: type.title, isSelected: viewModel.draft.type == type) {
                            viewModel.selectType(type)
                        }
                    }
                }

                section(Strings.DiscoverFilter.sectionSort) {
                    chipRow(DiscoverSort.allCases) { sort in
                        FilterChip(title: sort.title, isSelected: viewModel.draft.sort == sort) {
                            viewModel.selectSort(sort)
                        }
                    }
                }

                genresSection(viewModel)

                section(Strings.DiscoverFilter.sectionDecade) {
                    chipRow(ReleaseWindow.allCases) { window in
                        FilterChip(title: window.title, isSelected: viewModel.draft.releaseWindow == window) {
                            viewModel.selectReleaseWindow(window)
                        }
                    }
                }

                if !viewModel.providers.isEmpty {
                    section(Strings.DiscoverFilter.sectionProviders) {
                        chipRow(viewModel.providers) { provider in
                            FilterChip(
                                title: provider.providerName,
                                isSelected: viewModel.draft.providerIds.contains(provider.providerId)
                            ) {
                                viewModel.toggleProvider(provider.providerId)
                            }
                        }
                    }
                }

                applyButton
                    .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }

    /// Genres reload when the type changes, so the section holds its height with a spinner
    /// instead of collapsing and shoving everything below it up the screen.
    @ViewBuilder
    private func genresSection(_ viewModel: DiscoverFilterViewModel) -> some View {
        if viewModel.isLoadingGenres || !viewModel.genres.isEmpty {
            section(Strings.DiscoverFilter.sectionGenres) {
                if viewModel.isLoadingGenres {
                    ProgressView()
                        .frame(height: 30)
                        .padding(.horizontal)
                } else {
                    chipRow(viewModel.genres) { genre in
                        FilterChip(
                            title: genre.name,
                            isSelected: viewModel.draft.genreIds.contains(genre.id)
                        ) {
                            viewModel.toggleGenre(genre.id)
                        }
                    }
                }
            }
        }
    }

    private var applyButton: some View {
        Button {
            guard let viewModel else { return }
            let filter = viewModel.apply()
            dismiss()
            onApply(filter)
        } label: {
            Text(Strings.DiscoverFilter.apply)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressedButtonStyle())
        .padding(.horizontal)
    }

    // MARK: - Layout helpers

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: title)
                .font(.subheadline.bold())
                .padding(.horizontal)
            content()
        }
    }

    private func chipRow<Item: Identifiable, Chip: View>(
        _ items: [Item],
        @ViewBuilder chip: @escaping (Item) -> Chip
    ) -> some View {
        FlowLayout {
            ForEach(items, content: chip)
        }
        .padding(.horizontal)
    }
}

#Preview {
    DiscoverFilterView(initialFilter: DiscoverFilter()) { _ in }
        .environment(AppContainer.preview)
}
