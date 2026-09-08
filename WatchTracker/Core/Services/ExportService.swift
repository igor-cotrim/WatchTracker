import Foundation

protocol ExportServiceProtocol: Sendable {
    func fetchExport() async throws -> ExportPayload
}

final class ExportService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchExport() async throws -> ExportPayload {
        try await api.get(.exportData)
    }
}

extension ExportService: ExportServiceProtocol {}

/// Offline double for `#Preview` and `AppContainer.preview`.
struct PreviewExportService: ExportServiceProtocol {
    func fetchExport() async throws -> ExportPayload {
        ExportPayload(generatedAt: .now, unresolved: 0, items: [], episodes: [])
    }
}
