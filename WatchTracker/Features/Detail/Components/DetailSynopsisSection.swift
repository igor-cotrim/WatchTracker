import SwiftUI

struct DetailSynopsisSection: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: Strings.Detail.synopsis)
                .font(.headline)
            Text(verbatim: media.overview ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
