import SwiftUI

private enum WatchingTab {
    case watching, upcoming
}

struct WatchingView: View {
    @State private var viewModel = ContinueWatchingViewModel(
        service: WatchlistService(),
        store: WatchlistStore()
    )
    @State private var upcomingViewModel = UpcomingViewModel(
        service: WatchlistService()
    )
    @State private var selectedTab: WatchingTab = .watching

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text(Strings.Upcoming.tabWatching).tag(WatchingTab.watching)
                    Text(Strings.Upcoming.tabUpcoming).tag(WatchingTab.upcoming)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                Group {
                    switch selectedTab {
                    case .watching:
                        watchingContent
                    case .upcoming:
                        upcomingContent
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .navigationTitle(Strings.Watching.title)
            .background(Color(.systemGroupedBackground))
            .task { await viewModel.fetch() }
            .task(id: selectedTab) {
                if selectedTab == .upcoming && upcomingViewModel.items.isEmpty {
                    await upcomingViewModel.fetch()
                }
            }
            .refreshable {
                if selectedTab == .watching {
                    await viewModel.fetch()
                } else {
                    await upcomingViewModel.fetch()
                }
            }
        }
    }

    // MARK: - Watching content

    @ViewBuilder
    private var watchingContent: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            skeletonList
        } else if viewModel.items.isEmpty {
            ContentUnavailableView {
                Label(Strings.Watching.emptyTitle, systemImage: "play.rectangle.on.rectangle")
            } description: {
                Text(Strings.Watching.emptySubtitle)
            }
        } else {
            watchingList
        }
    }

    private var watchingList: some View {
        List {
            ForEach(viewModel.items) { item in
                WatchingRow(item: item) {
                    await viewModel.markAsWatched(item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.markAsWatched(item) }
                    } label: {
                        Label(Strings.Watching.markWatched, systemImage: "checkmark")
                    }
                    .tint(Color.brandPrimary)
                }
                .contextMenu {
                    Button {
                        Task { await viewModel.markAsWatched(item) }
                    } label: {
                        Label(Strings.Watching.markWatched, systemImage: "checkmark.circle")
                    }
                    NavigationLink {
                        MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
                    } label: {
                        Label(Strings.Watching.viewDetails, systemImage: "info.circle")
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .sensoryFeedback(.success, trigger: viewModel.items.count)
    }

    private var skeletonList: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                WatchingRowSkeleton()
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .allowsHitTesting(false)
    }

    // MARK: - Upcoming content

    @ViewBuilder
    private var upcomingContent: some View {
        if upcomingViewModel.isLoading && upcomingViewModel.items.isEmpty {
            upcomingSkeletonList
        } else if upcomingViewModel.items.isEmpty {
            ContentUnavailableView {
                Label(Strings.Upcoming.emptyTitle, systemImage: "calendar.badge.clock")
            } description: {
                Text(Strings.Upcoming.emptySubtitle)
            }
        } else {
            upcomingList
        }
    }

    private var upcomingList: some View {
        List {
            ForEach(upcomingViewModel.groupedItems, id: \.sectionKey) { section in
                Section {
                    ForEach(section.items) { item in
                        UpcomingRow(item: item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    UpcomingSectionHeader(sectionKey: section.sectionKey)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 4, for: .scrollContent)
    }

    private var upcomingSkeletonList: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                WatchingRowSkeleton()
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .allowsHitTesting(false)
    }
}
