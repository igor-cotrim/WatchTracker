import Foundation
import Testing
import Auth
@testable import WatchTracker

@Suite("Error.isConnectivityFailure", .tags(.pure))
struct ErrorConnectivityTests {

    @Test(arguments: [
        URLError.Code.notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
        .dnsLookupFailed,
        .cannotConnectToHost,
    ])
    func `transport failures are connectivity failures`(code: URLError.Code) {
        #expect(URLError(code).isConnectivityFailure)
    }

    /// A cancelled request is a dismissed screen or a superseded debounce. Treating it as
    /// offline would queue writes nobody made and retry work nobody wants.
    @Test(arguments: [URLError.Code.cancelled, .badURL, .unsupportedURL])
    func `other URL errors are not`(code: URLError.Code) {
        #expect(URLError(code).isConnectivityFailure == false)
    }

    @Test func `an APIError wrapping a transport failure is one too`() {
        #expect(APIError.networkError(URLError(.timedOut)).isConnectivityFailure)
    }

    @Test(arguments: [APIError.serverError, .notFound, .unauthorized, .rateLimited, .decodingError, .unknown])
    func `a server that answered is not a connectivity failure`(error: APIError) {
        #expect(error.isConnectivityFailure == false)
    }

    @Test func `a colliding code in another domain is not one`() {
        let error = NSError(domain: "com.example.Custom", code: URLError.timedOut.rawValue)
        #expect(error.isConnectivityFailure == false)
    }
}

@Suite("Error.indicatesLostSession", .tags(.pure))
struct ErrorLostSessionTests {

    private func apiError(status: Int) -> AuthError {
        .api(
            message: "invalid refresh token",
            errorCode: .sessionNotFound,
            underlyingData: Data(),
            underlyingResponse: HTTPURLResponse(
                url: URL(string: "https://example.supabase.co/auth/v1/token")!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
        )
    }

    @Test func `a missing session means signed out`() {
        #expect(AuthError.sessionMissing.indicatesLostSession)
    }

    @Test(arguments: [400, 401, 403])
    func `a refused refresh token means signed out`(status: Int) {
        #expect(apiError(status: status).indicatesLostSession)
    }

    /// Supabase being down is not the user being signed out.
    @Test(arguments: [500, 502, 503])
    func `a Supabase server error does not`(status: Int) {
        #expect(apiError(status: status).indicatesLostSession == false)
    }

    /// The whole point: a refresh that never reached Supabase says nothing about the session.
    @Test func `a dropped connection does not`() {
        #expect(URLError(.notConnectedToInternet).indicatesLostSession == false)
    }
}
