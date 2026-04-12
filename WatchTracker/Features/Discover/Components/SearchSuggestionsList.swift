import SwiftUI

struct SearchSuggestionsList: View {
    let suggestions: [MediaDetail]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: Strings.Discover.suggestions)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ForEach(suggestions) { item in
                SearchSuggestionRow(item: item)
            }
        }
    }
}
