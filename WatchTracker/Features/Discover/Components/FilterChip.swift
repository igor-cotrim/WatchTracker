import SwiftUI

/// One selectable capsule. `SearchFilterBar` had this shape inline; the filter sheet needs
/// the same chip for types, genres, sorts, decades and providers, so it lives here now.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var systemImage: String?
    let action: () -> Void

    init(
        title: String,
        isSelected: Bool,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(verbatim: title)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brandPrimary : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
