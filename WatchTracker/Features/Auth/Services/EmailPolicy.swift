import Foundation

/// The address rules enforced on sign-up. Deliberately pragmatic rather than
/// RFC 5322 complete: the goal is to catch a typo before a round trip to Supabase,
/// not to decide whether an exotic address is legal. Sign-in does not apply them —
/// only the server can say whether an address has an account behind it.
enum EmailPolicy {
    /// The SMTP limit on a full address; anything longer cannot be delivered.
    static let maximumLength = 254

    /// local@label(.label)*.tld — no spaces, no leading/trailing hyphen in a label,
    /// no consecutive dots, and a TLD of at least two letters.
    private static let pattern = #/[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}/#

    static func isValid(_ email: String) -> Bool {
        guard email.count <= maximumLength else { return false }
        guard !email.contains("..") else { return false }
        return email.wholeMatch(of: pattern) != nil
    }
}
