import Foundation
import Testing
@testable import WatchTracker

@Suite("ExportViewModel", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
@MainActor
struct ExportViewModelTests {

    /// A fresh scratch folder per test so the ViewModel never writes into the
    /// real temporary directory, and one test can't see another's files.
    private func makeViewModel() -> (ExportViewModel, MockExportService, MockAnalytics, URL) {
        let service = MockExportService()
        let analytics = MockAnalytics()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExportViewModelTests-\(UUID().uuidString)", isDirectory: true)
        let viewModel = ExportViewModel(
            service: service,
            analytics: analytics,
            directory: directory,
        )
        return (viewModel, service, analytics, directory)
    }

    @Test func `writes one file per generated CSV`() async throws {
        let (viewModel, service, _, directory) = makeViewModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        service.result = .success(TestFixtures.exportPayload(items: [
            TestFixtures.exportEntry(status: .completed, rating: 9),
            TestFixtures.exportEntry(tmdbId: 438631, title: "Dune", status: .planToWatch),
        ]))

        await viewModel.export(format: .letterboxd)

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isExporting == false)
        #expect(viewModel.result?.files.map(\.name) == ["watched.csv", "ratings.csv", "watchlist.csv"])
        #expect(viewModel.shareURLs.map { $0.lastPathComponent } == ["watched.csv", "ratings.csv", "watchlist.csv"])

        let watched = try #require(viewModel.shareURLs.first)
        let content = try String(contentsOf: watched, encoding: .utf8)
        #expect(content.hasPrefix("Date,Name,Year,Letterboxd URI\n"))
        #expect(content.contains("Fight Club"))
    }

    @Test func `reports the count of titles the backend could not resolve`() async {
        let (viewModel, service, _, directory) = makeViewModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        service.result = .success(TestFixtures.exportPayload(unresolved: 3))

        await viewModel.export(format: .letterboxd)

        #expect(viewModel.result?.unresolved == 3)
    }

    @Test func `surfaces an empty library instead of writing files`() async {
        let (viewModel, service, analytics, directory) = makeViewModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        service.result = .success(TestFixtures.exportPayload(items: []))

        await viewModel.export(format: .letterboxd)

        #expect(viewModel.errorMessage == Strings.Export.errorEmpty)
        #expect(viewModel.result == nil)
        #expect(viewModel.shareURLs.isEmpty)
        #expect(analytics.capturedEvents.isEmpty)
        #expect(viewModel.isExporting == false)
    }

    @Test func `surfaces a service failure`() async {
        let (viewModel, service, analytics, directory) = makeViewModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        service.result = .failure(APIError.serverError)

        await viewModel.export(format: .letterboxd)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.result == nil)
        #expect(viewModel.shareURLs.isEmpty)
        #expect(analytics.capturedEvents.isEmpty)
        #expect(viewModel.isExporting == false)
    }

    @Test func `clears the previous run before exporting again`() async throws {
        let (viewModel, service, _, directory) = makeViewModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        service.result = .success(TestFixtures.exportPayload(items: [
            TestFixtures.exportEntry(status: .completed),
            TestFixtures.exportEntry(tmdbId: 438631, title: "Dune", status: .planToWatch),
        ]))
        await viewModel.export(format: .letterboxd)

        // A shrinking library must not leave the old watchlist.csv behind to share.
        service.result = .success(TestFixtures.exportPayload(items: [
            TestFixtures.exportEntry(status: .completed),
        ]))
        await viewModel.export(format: .letterboxd)

        #expect(viewModel.shareURLs.map { $0.lastPathComponent } == ["watched.csv"])
        let folder = directory.appendingPathComponent("WatchTracker-Export", isDirectory: true)
        let written = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        #expect(written == ["watched.csv"])
    }

    @Test func `tracks the export`() async {
        let (viewModel, service, analytics, directory) = makeViewModel()
        defer { try? FileManager.default.removeItem(at: directory) }
        service.result = .success(TestFixtures.exportPayload(
            items: [
                TestFixtures.exportEntry(status: .completed, rating: 9),
                TestFixtures.exportEntry(tmdbId: 438631, title: "Dune", status: .planToWatch),
            ],
            unresolved: 1,
        ))

        await viewModel.export(format: .letterboxd)

        #expect(analytics.capturedEvents == [.dataExported])
        let properties = analytics.properties(for: .dataExported)
        #expect(properties?["files"] as? Int == 3)
        #expect(properties?["rows"] as? Int == 3)
        #expect(properties?["unresolved"] as? Int == 1)
    }
}
