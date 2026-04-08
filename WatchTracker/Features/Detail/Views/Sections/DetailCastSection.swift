import SwiftUI

struct DetailCastSection: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cast")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cast.prefix(20)) { member in
                        VStack {
                            AsyncImage(url: member.profileURL) { image in
                                image.resizable().aspectRatio(1, contentMode: .fill)
                            } placeholder: {
                                SkeletonView()
                                    .clipShape(Circle())
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())

                            Text(member.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Text(member.character ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
    }
}
