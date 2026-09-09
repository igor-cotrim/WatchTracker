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
            return Strings.Errors.unauthorized
        case .notFound:
            return Strings.Errors.notFound
        case .serverError:
            return Strings.Errors.server
        case .rateLimited:
            return Strings.Errors.rateLimited
        case .decodingError:
            return Strings.Errors.decoding
        case .networkError(let error):
            // A dropped connection gets the plain connection copy; anything else keeps the
            // underlying description, which is the only clue about what actually broke.
            return isConnectivity ? Strings.Common.connectionError
                                  : Strings.Errors.network(error.localizedDescription)
        case .unknown:
            return Strings.Errors.unknown
        }
    }

    /// `true` when the request never reached the backend.
    ///
    /// Callers branch on this rather than on the case itself: it is what separates "queue
    /// this write and keep the optimistic UI" from "the server refused it, put the row back".
    nonisolated var isConnectivity: Bool {
        guard case .networkError(let underlying) = self else { return false }
        let nsError = underlying as NSError
        return nsError.domain == NSURLErrorDomain
            && URLError.connectivityCodes.contains(nsError.code)
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
