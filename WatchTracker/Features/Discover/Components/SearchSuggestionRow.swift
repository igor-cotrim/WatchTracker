import SwiftUI

struct SearchSuggestionRow: View {
    let item: MediaDetail

    var body: some View {
        NavigationLink {
            MediaDetailView(mediaType: item.mediaType, mediaId: item.id)
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: item.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color(.systemGray5)
                            .overlay {
                                Image(systemName: "film")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(width: 40, height: 60)
                .clipShape(.rect(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: item.displayTitle)
                        .font(.subheadline).fontWeight(.medium)
                    if let year = item.releaseYear {
                        Text(verbatim: year)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
