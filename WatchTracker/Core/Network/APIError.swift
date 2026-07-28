import Foundation

enum APIError: LocalizedError, Equatable {
    case unauthorized
    case notFound
    case serverError
    case rateLimited
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
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .decodingError:
            return "Failed to process the server response."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
        }
    }

    /// `networkError` compares on the underlying `NSError` identity, since `Error`
    /// itself carries no equality.
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.serverError, .serverError),
             (.rateLimited, .rateLimited),
             (.decodingError, .decodingError),
             (.unknown, .unknown):
            return true
        case let (.networkError(lhsError), .networkError(rhsError)):
            return lhsError as NSError == rhsError as NSError
        default:
            return false
        }
    }
}
