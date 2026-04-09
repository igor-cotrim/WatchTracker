import SwiftUI

struct HomeView: View {
    @State private var viewModel = WatchlistViewModel()
    @Namespace private var pillNamespace

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status filter pills with animated selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        StatusPill(
                            label: Strings.Home.filterAll,
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

                // Media type filter
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(MediaFilter.allCases) { filter in
                        Text(verbatim: filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                WatchlistView(viewModel: viewModel)
            }
            .navigationTitle(Strings.Home.title)
            .task {
                await viewModel.fetchWatchlist()
            }
            .onChange(of: viewModel.selectedStatus) {
                Task { await viewModel.fetchWatchlist() }
            }
        }
    }
}

private struct StatusPill: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let namespace: Namespace.ID
    let pillID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(verbatim: label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
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
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
