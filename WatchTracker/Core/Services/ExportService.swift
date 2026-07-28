import Foundation

protocol ExportServiceProtocol: Sendable {
    func fetchExport() async throws -> ExportPayload
}

final class ExportService {
    private let api = APIClient.shared

    func fetchExport() async throws -> ExportPayload {
        try await api.get(.exportData)
    }
}

extension ExportService: ExportServiceProtocol {}
