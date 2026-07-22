import Foundation

protocol ImportServiceProtocol: Sendable {
    func importBatch(_ items: [ImportItem]) async throws -> ImportBatchResult
}
