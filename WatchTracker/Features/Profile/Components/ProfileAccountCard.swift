import SwiftUI
import Auth

struct ProfileAccountCard: View {
    let user: User?

    var body: some View {
        HStack(spacing: 13) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brandPrimary.opacity(0.85), Color.brandPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay {
                    Text(verbatim: initials)
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: displayName)
                    .font(.headline)
                    .lineLimit(1)

                if let email = user?.email, email != displayName {
                    Text(verbatim: email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if let memberSince {
                    Text(verbatim: Strings.Profile.memberSince(memberSince))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Derived values

    /// The name typed at sign-up, falling back to the email address.
    private var displayName: String {
        let name = user?.userMetadata["name"]?.stringValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let name, !name.isEmpty { return name }
        return user?.email ?? ""
    }

    private var initials: String {
        let words = displayName
            .split(whereSeparator: { $0 == " " || $0 == "@" || $0 == "." })
            .prefix(2)

        let letters = words.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    private var memberSince: String? {
        guard let createdAt = user?.createdAt else { return nil }
        return createdAt.formatted(.dateTime.month(.abbreviated).year())
    }
}
