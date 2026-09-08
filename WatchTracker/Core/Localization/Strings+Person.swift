import Foundation

extension Strings {
    // MARK: - Person

    enum Person {
        static var biography: String { String(localized: "person.biography.title") }
        static var readMore: String { String(localized: "person.biography.read_more") }
        static var readLess: String { String(localized: "person.biography.read_less") }
        static var appearsIn: String { String(localized: "person.appears_in.title") }
        static var noCredits: String { String(localized: "person.appears_in.empty") }
        static var openHint: String { String(localized: "person.open.hint") }

        /// "Dune, as Duke Leto Atreides" — read as one label by VoiceOver.
        static func creditAccessibility(title: String, character: String) -> String {
            String(format: String(localized: "person.credit.accessibility"), title, character)
        }
    }
}
