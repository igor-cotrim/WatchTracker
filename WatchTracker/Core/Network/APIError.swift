import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError
    case decodingError
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You are not authorized. Please sign in again."
        case .notFound:
            return "The requested resource was not found."
        case .serverError:
            return "A server error occurred. Please try again later."
        case .decodingError:
            return "Failed to process the server response."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
