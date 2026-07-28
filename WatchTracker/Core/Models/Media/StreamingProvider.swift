import Foundation

struct StreamingProvider: Codable, Identifiable {
    let providerId: Int
    let providerName: String
    let logoPath: String

    var id: Int { providerId }

    var logoURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w92\(logoPath)")
    }
}
