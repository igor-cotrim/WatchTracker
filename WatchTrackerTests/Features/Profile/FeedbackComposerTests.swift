import Foundation
import Testing
@testable import WatchTracker

@Suite("FeedbackComposer", .tags(.pure, .service))
@MainActor
struct FeedbackComposerTests {

    @Test func `body includes the diagnostics block`() {
        let body = FeedbackComposer.body(accountEmail: nil)
        #expect(body.contains(Strings.Feedback.diagnosticsTitle))
        #expect(body.contains(Strings.Feedback.fieldApp))
        #expect(body.contains(Strings.Feedback.fieldSystem))
        #expect(body.contains(Strings.Feedback.fieldDevice))
        #expect(body.contains(Strings.Feedback.fieldLanguage))
    }

    @Test func `body appends the account line when an email is provided`() {
        let body = FeedbackComposer.body(accountEmail: "user@example.com")
        #expect(body.contains("user@example.com"))
        #expect(body.contains(Strings.Feedback.fieldAccount))
    }

    @Test(arguments: [nil, ""])
    func `body omits the account line for a missing or empty email`(email: String?) {
        let body = FeedbackComposer.body(accountEmail: email)
        #expect(!body.contains(Strings.Feedback.fieldAccount))
    }

    @Test func `mailtoURL targets the support address`() throws {
        let url = try #require(FeedbackComposer.mailtoURL(accountEmail: nil))
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.contains(FeedbackComposer.recipient))
    }

    @Test func `mailtoURL carries the subject and body as query items`() throws {
        let url = try #require(FeedbackComposer.mailtoURL(accountEmail: "user@example.com"))
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)

        #expect(items.first(where: { $0.name == "subject" })?.value == FeedbackComposer.subject)
        #expect(items.first(where: { $0.name == "body" })?.value?.contains("user@example.com") == true)
    }

    @Test func `subject mentions the app name`() {
        #expect(FeedbackComposer.subject.contains(Bundle.main.appName))
    }
}
