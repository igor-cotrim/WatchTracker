import Foundation

/// A CSV file the user picked, before its format is known. `ImportParser` reads
/// `name` and the header row to decide which parser handles it.
struct ImportedFile: Sendable {
    let name: String
    let content: String
}
