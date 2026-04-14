import SwiftUI

struct StatusFilterBar: View {
    let viewModel: WatchlistViewModel
    @Namespace private var pillNamespace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StatusPill(
                    label: Strings.Home.filterAll,
                    count: nil,
                    isSelected: viewModel.selectedStatus == nil,
                    namespace: pillNamespace,
                    pillID: "all"
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.selectedStatus = nil
                    }
                }
                ForEach(WatchlistStatus.allCases, id: \.self) { status in
                    StatusPill(
                        label: status.displayName,
                        icon: status.icon,
                        count: viewModel.count(for: status),
                        isSelected: viewModel.selectedStatus == status,
                        namespace: pillNamespace,
                        pillID: status.rawValue
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewModel.selectedStatus = status
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct StatusPill: View {
    let label: String
    var icon: String? = nil
    var count: Int? = nil
    let isSelected: Bool
    let namespace: Namespace.ID
    let pillID: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            pillLabel
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var pillLabel: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(verbatim: label)
                .font(.subheadline)
            if let count, count > 0 {
                countBadge(count: count)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .foregroundStyle(isSelected ? .white : .primary)
        .background { pillBackground }
    }

    @ViewBuilder
    private func countBadge(count: Int) -> some View {
        Text(verbatim: "\(count)")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .foregroundStyle(isSelected ? .white : Color.brandPrimary)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.brandPrimary.opacity(0.15))
            )
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            Capsule()
                .fill(Color.brandPrimary)
                .matchedGeometryEffect(id: "selectedPill", in: namespace)
        } else {
            Capsule()
                .fill(Color.secondary.opacity(0.15))
        }
    }
}
