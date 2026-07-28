import Foundation
@testable import WatchTracker

@MainActor
final class MockImportService: ImportServiceProtocol {
    /// Applied to every batch. Defaults to "everything matched, nothing imported".
    var importBatchResult: ((ImportBatch) -> Result<ImportBatchResult, Error>)?
    var importBatchError: Error?

    private(set) var importBatchCalls: [ImportBatch] = []

    var batchSizes: [Int] { importBatchCalls.map(\.items.count) }
    var episodeBatchSizes: [Int] { importBatchCalls.map(\.episodes.count) }

    func importBatch(_ batch: ImportBatch) async throws -> ImportBatchResult {
        importBatchCalls.append(batch)
        if let importBatchError { throw importBatchError }
        if let importBatchResult { return try importBatchResult(batch).get() }
        return TestFixtures.importBatchResult(
            total: batch.items.count,
            matched: batch.items.count,
            episodes: batch.episodes.count,
        )
    }
}
