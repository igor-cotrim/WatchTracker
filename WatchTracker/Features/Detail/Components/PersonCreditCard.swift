import SwiftUI

/// One title in a person's filmography: the shared poster card plus the role they played,
/// which is the reason this wraps `PosterCardView` instead of using it directly.
struct PersonCreditCard: View {
    let credit: PersonCredit
    var width: CGFloat = 104

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            PosterCardView(url: credit.posterURL, title: credit.displayTitle, width: width)

            if let character = credit.character {
                Text(verbatim: character)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            credit.character.map { Strings.Person.creditAccessibility(title: credit.displayTitle, character: $0) }
                ?? credit.displayTitle
        )
        .accessibilityAddTraits(.isButton)
    }
}
