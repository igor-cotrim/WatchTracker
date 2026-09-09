import Foundation

extension Error {
    nonisolated var userFacingMessage: String {
        // `isConnectivityFailure` covers both a raw `URLError` and one already wrapped in
        // `APIError.networkError`, so a dropped connection reads the same wherever it
        // surfaced from.
        if isConnectivityFailure {
            return Strings.Common.connectionError
        }

        return localizedDescription
    }
}
