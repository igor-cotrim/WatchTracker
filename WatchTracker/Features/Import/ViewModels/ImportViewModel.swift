import Foundation

@Observable
@MainActor
final class ImportViewModel {
    struct Summary {
        var total: Int
        var matched: Int
        var watchlist: Int
        var ratings: Int
        var unmatched: [ImportBatchResult.UnmatchedItem]
    }

    var isImporting = false
    var progress: Double = 0
    var errorMessage: String?
    var result: Summary?

    private let service: ImportServiceProtocol
    private let batchSize = 100

    init(service: ImportServiceProtocol) {
        self.service = service
    }

    func importFiles(_ urls: [URL]) async {
        isImporting = true
        errorMessage = nil
        result = nil
        progress = 0

        do {
            let files = try readFiles(urls)
            let items = LetterboxdParser.parse(files: files)

            guard !items.isEmpty else {
                errorMessage = Strings.Import.errorEmpty
                isImporting = false
                return
            }

            var summary = Summary(total: items.count, matched: 0, watchlist: 0, ratings: 0, unmatched: [])
            var processed = 0

            for start in stride(from: 0, to: items.count, by: batchSize) {
                let batch = Array(items[start..<min(start + batchSize, items.count)])
                let batchResult = try await service.importBatch(batch)

                summary.matched += batchResult.matched
                summary.watchlist += batchResult.imported.watchlist
                summary.ratings += batchResult.imported.ratings
                summary.unmatched.append(contentsOf: batchResult.unmatched)

                processed += batch.count
                progress = Double(processed) / Double(items.count)
            }

            result = summary
        } catch {
            errorMessage = error.localizedDescription
        }

        isImporting = false
    }

    private func readFiles(_ urls: [URL]) throws -> [LetterboxdFile] {
        try urls.map { url in
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            return LetterboxdFile(
                name: url.lastPathComponent.lowercased(),
                content: String(decoding: data, as: UTF8.self),
            )
        }
    }
}
