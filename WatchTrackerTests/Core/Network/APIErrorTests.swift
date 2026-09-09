import Foundation
import Testing
@testable import WatchTracker

@Suite("APIError", .tags(.pure))
struct APIErrorTests {

    @Test(arguments: [
        APIError.unauthorized, .notFound, .serverError,
        .rateLimited, .decodingError, .unknown,
        .networkError(URLError(.timedOut)),
    ])
    func `every case has a description`(error: APIError) {
        #expect(error.errorDescription?.isEmpty == false)
    }

    /// A raw `NSURLError` string is no help to anyone, so the codes that mean "your
    /// connection dropped" get the copy written for exactly that.
    @Test func `networkError reads as a connection problem when it is one`() {
        #expect(APIError.networkError(URLError(.timedOut)).errorDescription == Strings.Common.connectionError)
    }

    @Test func `networkError surfaces the underlying message when it is not a connectivity failure`() {
        let underlying = URLError(.badServerResponse)
        let description = APIError.networkError(underlying).errorDescription
        #expect(description?.contains(underlying.localizedDescription) == true)
    }

    @Test func `distinct cases are not equal`() {
        #expect(APIError.notFound != APIError.serverError)
        #expect(APIError.notFound == APIError.notFound)
    }
}
