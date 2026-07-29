import Foundation

protocol ImportServiceProtocol: Sendable {
    func importBatch(_ batch: ImportBatch) async throws -> ImportBatchResult
}

final class ImportService {
    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func importBatch(_ batch: ImportBatch) async throws -> ImportBatchResult {
        try await api.post(.importData(batch: batch))
    }
}

extension ImportService: ImportServiceProtocol {}
