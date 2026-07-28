import Foundation
import Testing
@testable import WatchTracker

@Suite("AuthServiceError", .tags(.pure))
struct AuthServiceErrorTests {

    @Test func `emailConfirmationRequired surfaces the localized message`() {
        let error = AuthServiceError.emailConfirmationRequired
        #expect(error.userFacingMessage == Strings.Auth.emailConfirmationRequired)
    }

    @Test func `emailConfirmationRequired resolves a real catalog entry`() {
        // String(localized:) echoes the key back when it is missing from the catalog,
        // which would ship the raw "auth.email_confirmation_required" to the user.
        #expect(Strings.Auth.emailConfirmationRequired != "auth.email_confirmation_required")
    }
}
