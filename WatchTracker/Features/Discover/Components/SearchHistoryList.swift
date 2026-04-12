import SwiftUI

struct SearchHistoryList: View {
    let history: [String]
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        if !history.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(verbatim: Strings.Discover.recentSearches)
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Button(Strings.Discover.clear) { onClear() }
                        .font(.caption)
                }
                .padding(.horizontal)

                ForEach(history, id: \.self) { query in
                    HStack {
                        Button {
                            onSelect(query)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath").foregroundStyle(.secondary)
                                Text(verbatim: query).font(.subheadline)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            onRemove(query)
                        } label: {
                            Image(systemName: "xmark").font(.caption).foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
