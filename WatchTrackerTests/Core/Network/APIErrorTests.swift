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

    @Test func `networkError surfaces the underlying message`() {
        let underlying = URLError(.timedOut)
        let description = APIError.networkError(underlying).errorDescription
        #expect(description?.contains(underlying.localizedDescription) == true)
    }

    @Test func `distinct cases are not equal`() {
        #expect(APIError.notFound != APIError.serverError)
        #expect(APIError.notFound == APIError.notFound)
    }
}
