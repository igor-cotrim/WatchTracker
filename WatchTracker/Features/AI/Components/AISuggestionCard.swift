import SwiftUI

struct AISuggestionCard: View {
    let media: MediaDetail
    let reason: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: media.posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                SkeletonView()
            }
            .frame(width: 80, height: 120)
            .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: media.displayTitle)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(media.mediaType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.brandPrimary.opacity(0.15))
                        .foregroundStyle(Color.brandPrimary)
                        .clipShape(Capsule())

                    if let year = media.releaseYear {
                        Text(verbatim: year)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(verbatim: reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
}
