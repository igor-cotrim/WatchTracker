import Testing
@testable import WatchTracker

@Suite("EmailPolicy", .tags(.pure))
struct EmailPolicyTests {

    @Test(arguments: [
        "user@example.com",
        "user.name@example.com",
        "user+tag@example.com",
        "user_name%test-1@example.co.uk",
        "u@e.io",
        "user@sub.domain.example.com",
        "user@my-host.com"
    ])
    func `isValid accepts a well-formed address`(email: String) {
        #expect(EmailPolicy.isValid(email))
    }

    @Test(arguments: [
        "",
        "user",                     // no domain
        "user@",                    // no host
        "@example.com",             // no local part
        "user@example",             // no TLD
        "user@example.c",           // one-letter TLD
        "user@.com",                // empty label
        "user@@example.com",
        "user@exa mple.com",        // space in the host
        "user name@example.com",    // space in the local part
        "user@example..com",        // consecutive dots
        "user..name@example.com",
        "user@-example.com",        // label starts with a hyphen
        "user@example-.com",        // label ends with a hyphen
        "user@example.com ",        // a trailing space is still invalid
        " user@example.com"
    ])
    func `isValid rejects a malformed address`(email: String) {
        #expect(!EmailPolicy.isValid(email))
    }

    /// The address as a whole cannot exceed the SMTP limit, even when every
    /// character of it is legal.
    @Test func `isValid rejects an address past the SMTP length limit`() {
        let suffix = "@example.com"
        let local = String(repeating: "a", count: EmailPolicy.maximumLength - suffix.count)

        #expect(EmailPolicy.isValid(local + suffix))
        #expect(!EmailPolicy.isValid(local + "a" + suffix))
    }
}
