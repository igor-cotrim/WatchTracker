import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var viewModel = ImportViewModel(service: ImportService())
    @State private var showFileImporter = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Import.instructionsTitle)
                        .font(.headline)
                    Text(Strings.Import.instructionsBody)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    showFileImporter = true
                } label: {
                    HStack {
                        Label(Strings.Import.pickFile, systemImage: "doc.badge.plus")
                        if viewModel.isImporting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isImporting)
            } footer: {
                Text(Strings.Import.pickFileHint)
            }

            if viewModel.isImporting {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: viewModel.progress)
                        Text(Strings.Import.importing)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(verbatim: errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if let result = viewModel.result {
                resultSections(result)
            }
        }
        .navigationTitle(Strings.Import.title)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: true,
        ) { outcome in
            switch outcome {
            case .success(let urls):
                Task { await viewModel.importFiles(urls) }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func resultSections(_ result: ImportViewModel.Summary) -> some View {
        Section(Strings.Import.resultsTitle) {
            summaryRow(Strings.Import.resultMatched, value: "\(result.matched)/\(result.total)")
            summaryRow(Strings.Import.resultWatchlist, value: "\(result.watchlist)")
            summaryRow(Strings.Import.resultRatings, value: "\(result.ratings)")
        }

        if !result.unmatched.isEmpty {
            Section(Strings.Import.unmatchedTitle) {
                ForEach(Array(result.unmatched.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(verbatim: item.title)
                        if let year = item.year {
                            Spacer()
                            Text(verbatim: "\(year)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(verbatim: value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
}
