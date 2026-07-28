import Foundation

/// A generated CSV file, held in memory until the ViewModel writes it to disk.
struct ExportFile: Equatable, Sendable {
    let name: String
    let content: String
    /// Data rows, excluding the header — what the results screen shows.
    let rowCount: Int
}
