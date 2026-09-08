import SwiftUI

struct DetailCastSection: View {
    let cast: [CastMember]

    /// TMDB orders `cast` by billing, so the first 20 are the names anyone would
    /// recognise; past that it turns into uncredited extras.
    private var billed: ArraySlice<CastMember> { cast.prefix(20) }

    /// When nobody in the list has a character name there is no second line to align,
    /// so the cards drop it instead of every one reserving an empty row.
    private var showsCharacters: Bool {
        billed.contains { !($0.character ?? "").isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Detail.cast)
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(billed) { member in
                        NavigationLink {
                            PersonView(personId: member.id, personName: member.name)
                        } label: {
                            CastMemberCard(member: member, showsCharacter: showsCharacters)
                        }
                        .buttonStyle(PressedButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct CastMemberCard: View {
    let member: CastMember
    let showsCharacter: Bool

    private static let avatarSize: CGFloat = 72

    var body: some View {
        VStack(spacing: 5) {
            AsyncImage(url: member.profileURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .empty where member.profileURL != nil:
                    SkeletonView()
                default:
                    placeholder
                }
            }
            .frame(width: Self.avatarSize, height: Self.avatarSize)
            .clipShape(Circle())

            // One line each, always. Letting a long name wrap pushed that card's character
            // label a row below its neighbours' and the whole carousel read as ragged —
            // truncating is the trade that keeps every label on the same baseline.
            Text(verbatim: member.name)
                .font(.caption2.weight(.medium))
                .lineLimit(1)

            if showsCharacter {
                Text(verbatim: member.character ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1, reservesSpace: true)
            }
        }
        .frame(width: 96)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Strings.Person.openHint)
    }

    private var placeholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.systemGray3))
            }
    }
}
