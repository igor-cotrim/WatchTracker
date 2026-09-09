import Foundation
import Auth

/// Classifying *why* a call failed, which on a mobile connection is a different question
/// from what to tell the user about it (`Error+UserMessage`).
///
/// Two distinctions carry the app's whole offline behaviour:
/// "the request never reached the server" decides whether a failed write is queued or
/// reverted and whether a failed load blanks the screen or just shows a banner, and
/// "Supabase says the session is gone" decides whether the user is signed out — because a
/// token refresh that could not reach Supabase must never be read as an expired session.
extension Error {
    /// `true` when the connection failed rather than the server answering: no route to the
    /// internet, DNS, a dropped socket, or a timeout.
    nonisolated var isConnectivityFailure: Bool {
        if let apiError = self as? APIError {
            return apiError.isConnectivity
        }
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain
            && URLError.connectivityCodes.contains(nsError.code)
    }

    /// `true` when Supabase is telling us the session itself is missing or was rejected —
    /// the only failures that may sign the user out.
    ///
    /// Everything else, a refresh that never reached Supabase above all, leaves the last
    /// known auth state standing: the alternative strands an offline user on a login screen
    /// they cannot use.
    nonisolated var indicatesLostSession: Bool {
        guard let authError = self as? AuthError else { return false }
        switch authError {
        case .sessionMissing:
            return true
        case .api(_, _, _, let response):
            // 400/401/403 from the token endpoint is a refused refresh token, not a bad link.
            return (400...403).contains(response.statusCode)
        default:
            return false
        }
    }
}

extension URLError {
    /// `URLError` codes that mean the request never reached the server.
    ///
    /// `.cancelled` is deliberately absent: a cancelled debounce or a dismissed screen is
    /// not a connection problem and must not be retried, queued or reported.
    nonisolated static let connectivityCodes: Set<Int> = [
        URLError.notConnectedToInternet.rawValue,
        URLError.cannotFindHost.rawValue,
        URLError.cannotConnectToHost.rawValue,
        URLError.networkConnectionLost.rawValue,
        URLError.dnsLookupFailed.rawValue,
        URLError.timedOut.rawValue,
        URLError.dataNotAllowed.rawValue,
        URLError.internationalRoamingOff.rawValue,
        URLError.secureConnectionFailed.rawValue,
        URLError.resourceUnavailable.rawValue
    ]

    /// Codes worth a second attempt: the ones a flaky link produces and a stable one does not.
    ///
    /// A retry only helps where the failure is about *this* attempt, so a device with data
    /// switched off (`.dataNotAllowed`) or roaming disabled is excluded — those fail
    /// identically every time.
    nonisolated static let transientCodes: Set<Int> = [
        URLError.networkConnectionLost.rawValue,
        URLError.timedOut.rawValue,
        URLError.cannotConnectToHost.rawValue,
        URLError.cannotFindHost.rawValue,
        URLError.dnsLookupFailed.rawValue,
        URLError.secureConnectionFailed.rawValue
    ]

    nonisolated var isTransient: Bool {
        URLError.transientCodes.contains(errorCode)
    }
}
