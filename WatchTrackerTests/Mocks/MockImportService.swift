import Foundation
@testable import WatchTracker

@MainActor
final class MockImportService: ImportServiceProtocol {
    /// Applied to every batch. Defaults to "everything matched, nothing imported".
    var importBatchResult: (([ImportItem]) -> Result<ImportBatchResult, Error>)?
    var importBatchError: Error?

    private(set) var importBatchCalls: [[ImportItem]] = []

    var batchSizes: [Int] { importBatchCalls.map(\.count) }

    func importBatch(_ items: [ImportItem]) async throws -> ImportBatchResult {
        importBatchCalls.append(items)
        if let importBatchError { throw importBatchError }
        if let importBatchResult { return try importBatchResult(items).get() }
        return TestFixtures.importBatchResult(total: items.count, matched: items.count)
    }
}
