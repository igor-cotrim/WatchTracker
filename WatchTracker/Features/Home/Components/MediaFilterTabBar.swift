import SwiftUI

struct MediaFilterTabBar: View {
    @Binding var selected: MediaFilter

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MediaFilter.allCases) { filter in
                tabButton(for: filter)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func tabButton(for filter: MediaFilter) -> some View {
        let isSelected = selected == filter
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selected = filter
            }
        } label: {
            tabLabel(filter: filter, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tabLabel(filter: MediaFilter, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: filter.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.brandPrimary : .secondary)
                .frame(maxWidth: .infinity)
            Capsule()
                .fill(isSelected ? Color.brandPrimary : Color.clear)
                .frame(height: 2)
        }
        .contentShape(Rectangle())
    }
}
