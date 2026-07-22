import Foundation

final class ImportService {
    private let api = APIClient.shared

    func importBatch(_ items: [ImportItem]) async throws -> ImportBatchResult {
        try await api.post(.importData(items: items))
    }
}

extension ImportService: ImportServiceProtocol {}
