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
    private let batchSize: Int

    init(service: ImportServiceProtocol, batchSize: Int = 100) {
        self.service = service
        self.batchSize = batchSize
    }

    func importFiles(_ urls: [URL]) async {
        do {
            let files = try readFiles(urls)
            await importItems(LetterboxdParser.parse(files: files))
        } catch {
            errorMessage = error.localizedDescription
            isImporting = false
        }
    }

    /// Uploads already-parsed items in batches. Split out of `importFiles` so the
    /// batching and progress logic is reachable without security-scoped file URLs.
    func importItems(_ items: [ImportItem]) async {
        isImporting = true
        errorMessage = nil
        result = nil
        progress = 0

        do {
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
