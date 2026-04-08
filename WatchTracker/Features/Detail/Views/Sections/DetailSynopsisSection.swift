import SwiftUI

struct DetailSynopsisSection: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            Text(media.overview ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
