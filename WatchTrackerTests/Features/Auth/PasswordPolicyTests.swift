import Testing
@testable import WatchTracker

@Suite("PasswordPolicy", .tags(.pure))
struct PasswordPolicyTests {

    @Test(arguments: [
        (password: "Abcdefg1", expected: true),   // exactly the minimum
        (password: "Abcdef1", expected: false),   // one short
        (password: "", expected: false),
        (password: "AAAAAAAAAAAA1", expected: true)
    ])
    func `hasMinLength requires eight characters`(password: String, expected: Bool) {
        #expect(PasswordPolicy.hasMinLength(password) == expected)
    }

    @Test(arguments: [
        (password: "abcdefg1", expected: false),
        (password: "abcdefG1", expected: true),
        (password: "abcdefg!", expected: false),
        // The rule is `[A-Z]`, so a capital outside ASCII does not satisfy it —
        // a user typing an all-accented password sees the requirement stay unmet.
        (password: "áçãõéúí1", expected: false),
        (password: "ÁÇÃÕÉÚÍ1", expected: false)
    ])
    func `hasUppercase looks for an ASCII capital`(password: String, expected: Bool) {
        #expect(PasswordPolicy.hasUppercase(password) == expected)
    }

    @Test(arguments: [
        (password: "Abcdefgh", expected: false),
        (password: "Abcdefg0", expected: true),
        (password: "9bcdefgh", expected: true)
    ])
    func `hasNumber looks for a digit`(password: String, expected: Bool) {
        #expect(PasswordPolicy.hasNumber(password) == expected)
    }

    @Test(arguments: [
        (password: "Password1", expected: true),
        (password: "password1", expected: false),   // no uppercase
        (password: "PASSWORD", expected: false),    // no digit
        (password: "Pass1", expected: false),       // too short
        (password: "", expected: false)
    ])
    func `isValid requires all three rules`(password: String, expected: Bool) {
        #expect(PasswordPolicy.isValid(password) == expected)
    }
}
