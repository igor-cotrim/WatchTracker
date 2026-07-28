import Foundation
import Testing
import UIKit
@testable import WatchTracker

@Suite("Error.userFacingMessage", .tags(.pure))
struct ErrorUserMessageTests {

    /// Every URLError code that should surface the friendly "check your connection" copy.
    static let connectionCodes: [URLError.Code] = [
        .notConnectedToInternet,
        .cannotFindHost,
        .cannotConnectToHost,
        .networkConnectionLost,
        .dnsLookupFailed,
        .timedOut,
        .dataNotAllowed,
        .internationalRoamingOff,
    ]

    @Test(arguments: connectionCodes)
    func `connection failures map to the shared connection message`(code: URLError.Code) {
        #expect(URLError(code).userFacingMessage == Strings.Common.connectionError)
    }

    @Test(arguments: [URLError.Code.badURL, .unsupportedURL, .cancelled, .fileDoesNotExist])
    func `other URL errors fall through to localizedDescription`(code: URLError.Code) {
        let error = URLError(code)
        #expect(error.userFacingMessage == error.localizedDescription)
    }

    @Test(arguments: [APIError.notFound, .serverError, .unauthorized, .decodingError, .rateLimited, .unknown])
    func `APIError falls through to its own description`(error: APIError) {
        #expect(error.userFacingMessage == error.localizedDescription)
    }

    @Test func `a colliding code in another domain is not treated as a connection error`() {
        // -1009 is `notConnectedToInternet`, but only inside NSURLErrorDomain.
        let error = NSError(domain: "com.example.Custom", code: URLError.notConnectedToInternet.rawValue)
        #expect(error.userFacingMessage != Strings.Common.connectionError)
    }
}

@Suite("Bundle app info", .tags(.pure))
struct BundleAppInfoTests {

    @Test func `appVersionWithBuild is version then build in parentheses`() {
        let bundle = Bundle(for: BundleAppInfoProbe.self)
        #expect(bundle.appVersionWithBuild == "\(bundle.appVersion) (\(bundle.appBuild))")
    }

    @Test func `currentLanguageName is non-empty and capitalised`() {
        let name = Bundle.main.currentLanguageName
        #expect(!name.isEmpty)
        #expect(name.first?.isUppercase == true)
    }

    @Test func `hardwareIdentifier is non-empty`() {
        #expect(!UIDevice.hardwareIdentifier.isEmpty)
    }
}

/// Anchor class used to resolve the test bundle for `Bundle(for:)`.
private final class BundleAppInfoProbe {}
