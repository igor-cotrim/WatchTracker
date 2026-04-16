import SwiftUI

struct AISuggestionsView: View {
    @State private var viewModel = AISuggestionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.availability == .available {
                    availableContent
                } else {
                    AIUnavailableView(availability: viewModel.availability)
                }
            }
            .navigationTitle(Strings.AI.title)
            .searchable(text: $viewModel.userInput, prompt: Strings.AI.promptPlaceholder)
            .onSubmit(of: .search) {
                guard !viewModel.isLoading else { return }
                Task { await viewModel.refresh() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.userInput = ""
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    @ViewBuilder
    private var availableContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            ErrorStateView(message: error) {
                await viewModel.generateSuggestions()
            }
        } else if viewModel.suggestions.isEmpty && viewModel.hasGenerated {
            ContentUnavailableView {
                Label(Strings.AI.emptyTitle, systemImage: "sparkles")
            } description: {
                Text(Strings.AI.emptySubtitle)
            }
        } else if viewModel.suggestions.isEmpty {
            idleView
        } else {
            suggestionsListView
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: 8) {
                Text(Strings.AI.idleTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(Strings.AI.idleSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach([Strings.AI.exampleAnime, Strings.AI.exampleMovie, Strings.AI.exampleMood], id: \.self) { example in
                    AIExampleChip(text: example) {
                        viewModel.userInput = example
                        Task { await viewModel.refresh() }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(Strings.AI.loading)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var suggestionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.suggestions) { item in
                    NavigationLink {
                        MediaDetailView(mediaType: item.media.mediaType, mediaId: item.media.id)
                    } label: {
                        AISuggestionCard(media: item.media, reason: item.suggestion.reason)
                    }
                    .buttonStyle(PressedButtonStyle())
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

private struct AIExampleChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle")
                    .font(.caption)
                Text(verbatim: text)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.brandPrimary.opacity(0.1))
            .foregroundStyle(Color.brandPrimary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    AISuggestionsView()
}
