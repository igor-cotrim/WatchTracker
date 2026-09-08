import Foundation

@Observable
@MainActor
final class ImportViewModel {
    struct Summary {
        var total: Int
        var matched: Int
        var watchlist: Int
        var ratings: Int
        var episodes: Int
        var unmatched: [ImportBatchResult.UnmatchedItem]
    }

    var isImporting = false
    var progress: Double = 0
    var errorMessage: String?
    var result: Summary?

    private let service: ImportServiceProtocol
    private let batchSize: Int
    private let episodeBatchSize: Int

    init(
        service: ImportServiceProtocol,
        batchSize: Int = 100,
        episodeBatchSize: Int = 400,
    ) {
        self.service = service
        self.batchSize = batchSize
        self.episodeBatchSize = episodeBatchSize
    }

    func importFiles(_ urls: [URL]) async {
        do {
            let files = try readFiles(urls)
            await importBatch(ImportParser.parse(files: files))
        } catch {
            errorMessage = error.userFacingMessage
            isImporting = false
        }
    }

    /// Uploads an already-parsed batch. Split out of `importFiles` so the batching
    /// and progress logic is reachable without security-scoped file URLs.
    func importBatch(_ batch: ImportBatch) async {
        isImporting = true
        errorMessage = nil
        result = nil
        progress = 0

        do {
            guard !batch.isEmpty else {
                errorMessage = Strings.Import.errorEmpty
                isImporting = false
                return
            }

            // Items and episodes are chunked separately — a show with hundreds of
            // watched episodes shouldn't inflate the title batches.
            let chunks = itemChunks(batch.items) + episodeChunks(batch.episodes)

            var summary = Summary(
                total: batch.items.count,
                matched: 0,
                watchlist: 0,
                ratings: 0,
                episodes: 0,
                unmatched: [],
            )

            for (index, chunk) in chunks.enumerated() {
                let chunkResult = try await service.importBatch(chunk)

                summary.matched += chunkResult.matched
                summary.watchlist += chunkResult.imported.watchlist
                summary.ratings += chunkResult.imported.ratings
                summary.episodes += chunkResult.imported.episodes
                summary.unmatched.append(contentsOf: chunkResult.unmatched)

                progress = Double(index + 1) / Double(chunks.count)
            }

            result = summary
        } catch {
            errorMessage = error.userFacingMessage
        }

        isImporting = false
    }

    // MARK: - Helpers

    private func itemChunks(_ items: [ImportItem]) -> [ImportBatch] {
        stride(from: 0, to: items.count, by: batchSize).map { start in
            let end = min(start + batchSize, items.count)
            return ImportBatch(items: Array(items[start..<end]))
        }
    }

    private func episodeChunks(_ episodes: [ImportEpisode]) -> [ImportBatch] {
        stride(from: 0, to: episodes.count, by: episodeBatchSize).map { start in
            let end = min(start + episodeBatchSize, episodes.count)
            return ImportBatch(episodes: Array(episodes[start..<end]))
        }
    }

    private func readFiles(_ urls: [URL]) throws -> [ImportedFile] {
        try urls.map { url in
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            return ImportedFile(
                name: url.lastPathComponent.lowercased(),
                content: String(decoding: data, as: UTF8.self),
            )
        }
    }
}
