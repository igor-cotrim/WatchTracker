import Foundation

protocol ExportServiceProtocol: Sendable {
    func fetchExport() async throws -> ExportPayload
}

final class ExportService {
    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func fetchExport() async throws -> ExportPayload {
        try await api.get(.exportData)
    }
}

extension ExportService: ExportServiceProtocol {}
