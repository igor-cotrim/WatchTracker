import SwiftUI
import UniformTypeIdentifiers

/// One screen for both halves of moving a library in and out of WatchTracker.
struct DataView: View {
    @State private var exportViewModel: ExportViewModel
    @State private var importViewModel: ImportViewModel
    @State private var format: ExportFormat = .watchTracker
    @State private var showFileImporter = false

    init(container: AppContainer) {
        _exportViewModel = State(wrappedValue: container.makeExportViewModel())
        _importViewModel = State(wrappedValue: container.makeImportViewModel())
    }

    var body: some View {
        List {
            exportSection

            if let result = exportViewModel.result {
                exportResultSection(result)
            }

            importSection

            if let result = importViewModel.result {
                importResultSections(result)
            }
        }
        .navigationTitle(Strings.Data.title)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: true,
        ) { outcome in
            switch outcome {
            case .success(let urls):
                Task { await importViewModel.importFiles(urls) }
            case .failure(let error):
                importViewModel.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Export

    @ViewBuilder
    private var exportSection: some View {
        Section {
            Picker(Strings.Export.format, selection: $format) {
                ForEach(ExportFormat.allCases) { option in
                    Text(verbatim: option.title).tag(option)
                }
            }
            .disabled(exportViewModel.isExporting)

            Button {
                Task { await exportViewModel.export(format: format) }
            } label: {
                HStack {
                    Label(Strings.Export.action, systemImage: "square.and.arrow.up")
                    if exportViewModel.isExporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(exportViewModel.isExporting)

            if let errorMessage = exportViewModel.errorMessage {
                Text(verbatim: errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text(Strings.Data.exportSection)
        } footer: {
            Text(exportViewModel.isExporting ? Strings.Export.exporting : format.summary)
        }
    }

    @ViewBuilder
    private func exportResultSection(_ result: ExportViewModel.Summary) -> some View {
        Section {
            ForEach(result.files, id: \.name) { file in
                LabeledContent {
                    Text(Strings.Export.fileRows(file.rowCount))
                } label: {
                    Text(verbatim: file.name)
                }
            }

            if !exportViewModel.shareURLs.isEmpty {
                ShareLink(items: exportViewModel.shareURLs) {
                    Label(Strings.Export.share, systemImage: "square.and.arrow.up.on.square")
                }
            }
        } header: {
            Text(Strings.Export.resultsTitle)
        } footer: {
            if result.unresolved > 0 {
                Text(Strings.Export.unresolved(result.unresolved))
            }
        }
    }

    // MARK: - Import

    @ViewBuilder
    private var importSection: some View {
        Section {
            Button {
                showFileImporter = true
            } label: {
                HStack {
                    Label(Strings.Import.pickFile, systemImage: "square.and.arrow.down")
                    if importViewModel.isImporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(importViewModel.isImporting)

            if importViewModel.isImporting {
                ProgressView(value: importViewModel.progress)
            }

            if let errorMessage = importViewModel.errorMessage {
                Text(verbatim: errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text(Strings.Data.importSection)
        } footer: {
            Text(importViewModel.isImporting ? Strings.Import.importing : Strings.Import.pickFileHint)
        }
    }

    @ViewBuilder
    private func importResultSections(_ result: ImportViewModel.Summary) -> some View {
        Section(Strings.Import.resultsTitle) {
            summaryRow(Strings.Import.resultMatched, value: "\(result.matched)/\(result.total)")
            summaryRow(Strings.Import.resultWatchlist, value: "\(result.watchlist)")
            summaryRow(Strings.Import.resultRatings, value: "\(result.ratings)")
            if result.episodes > 0 {
                summaryRow(Strings.Import.resultEpisodes, value: "\(result.episodes)")
            }
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
        LabeledContent {
            Text(verbatim: value).fontWeight(.medium)
        } label: {
            Text(title)
        }
    }
}

#Preview {
    NavigationStack {
        DataView(container: .preview)
    }
}
