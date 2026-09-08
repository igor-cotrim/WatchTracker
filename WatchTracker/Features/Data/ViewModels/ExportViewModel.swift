import Foundation

@Observable
@MainActor
final class ExportViewModel {
    struct Summary {
        var files: [ExportFile]
        var unresolved: Int
    }

    var isExporting = false
    var errorMessage: String?
    var result: Summary?
    var shareURLs: [URL] = []

    private let service: ExportServiceProtocol
    private let analytics: AnalyticsTracking
    private let directory: URL

    init(
        service: ExportServiceProtocol,
        analytics: AnalyticsTracking,
        directory: URL = FileManager.default.temporaryDirectory,
    ) {
        self.service = service
        self.analytics = analytics
        self.directory = directory
    }

    func export(format: ExportFormat) async {
        isExporting = true
        errorMessage = nil
        result = nil
        shareURLs = []

        do {
            let payload = try await service.fetchExport()
            let files = switch format {
            case .watchTracker: WatchTrackerExporter.files(from: payload)
            case .letterboxd: LetterboxdExporter.files(from: payload)
            }

            guard !files.isEmpty else {
                errorMessage = Strings.Export.errorEmpty
                isExporting = false
                return
            }

            shareURLs = try write(files)
            result = Summary(files: files, unresolved: payload.unresolved)

            analytics.capture(.dataExported, properties: [
                "format": format.rawValue,
                "files": files.count,
                "rows": files.reduce(0) { $0 + $1.rowCount },
                "unresolved": payload.unresolved,
            ])
        } catch {
            errorMessage = error.userFacingMessage
        }

        isExporting = false
    }

    /// Writes the generated files into a dedicated subfolder, recreated on every
    /// run so a shrinking library never leaves a stale file behind to be shared.
    private func write(_ files: [ExportFile]) throws -> [URL] {
        let folder = directory.appendingPathComponent("WatchTracker-Export", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        return try files.map { file in
            let url = folder.appendingPathComponent(file.name)
            try file.content.write(to: url, atomically: true, encoding: .utf8)
            return url
        }
    }
}
