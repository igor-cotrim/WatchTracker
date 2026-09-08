import Foundation

protocol ImportServiceProtocol: Sendable {
    func importBatch(_ batch: ImportBatch) async throws -> ImportBatchResult
}

final class ImportService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func importBatch(_ batch: ImportBatch) async throws -> ImportBatchResult {
        try await api.post(.importData(batch: batch))
    }
}

extension ImportService: ImportServiceProtocol {}

/// Offline double for `#Preview` and `AppContainer.preview`.
struct PreviewImportService: ImportServiceProtocol {
    func importBatch(_ batch: ImportBatch) async throws -> ImportBatchResult {
        ImportBatchResult(
            total: batch.items.count,
            matched: batch.items.count,
            imported: ImportBatchResult.Counts(watchlist: batch.items.count, ratings: 0, episodes: 0),
            unmatched: []
        )
    }
}
