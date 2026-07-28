import Foundation
@testable import WatchTracker

@MainActor
final class MockExportService: ExportServiceProtocol {
    var result: Result<ExportPayload, Error> = .success(TestFixtures.exportPayload())

    private(set) var fetchCallCount = 0

    func fetchExport() async throws -> ExportPayload {
        fetchCallCount += 1
        return try result.get()
    }
}
