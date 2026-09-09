import SwiftUI

private enum WatchingTab {
    case watching, upcoming
}

struct WatchingView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AppContainer.self) private var container
    @State private var viewModel: ContinueWatchingViewModel
    @State private var upcomingViewModel: UpcomingViewModel
    @State private var selectedTab: WatchingTab = .watching
    @State private var navigationPath = NavigationPath()

    init(container: AppContainer) {
        _viewModel = State(wrappedValue: container.makeContinueWatchingViewModel())
        _upcomingViewModel = State(wrappedValue: container.makeUpcomingViewModel())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationDestination(for: Int.self) { tmdbId in
                MediaDetailView(mediaType: .tv, mediaId: tmdbId)
            }
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
            .onChange(of: appRouter.pendingShowId) { _, id in
                guard let id else { return }
                navigationPath.append(id)
                appRouter.pendingShowId = nil
            }
            // Both lists are stale the moment they were fetched without a connection, and
            // the queued "mark watched" writes have just been replayed by `AppTabView`.
            .onChange(of: container.network.isOnline) { _, isOnline in
                guard isOnline else { return }
                Task {
                    await viewModel.fetch()
                    if selectedTab == .upcoming { await upcomingViewModel.fetch() }
                }
            }
        }
    }

    // MARK: - Watching content

    @ViewBuilder
    private var watchingContent: some View {
        VStack(spacing: 0) {
            if let stale = viewModel.staleMessage {
                NoticeBanner(message: stale, systemImage: "clock.arrow.circlepath", tint: .secondary)
            }

            if viewModel.isLoading && viewModel.items.isEmpty {
                skeletonList
            } else if let error = viewModel.errorMessage {
                // Only reached with nothing on screen: with rows loaded the same failure is
                // the banner above instead.
                ErrorStateView(message: error) {
                    await viewModel.fetch()
                }
                Spacer(minLength: 0)
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
        VStack(spacing: 0) {
            if let stale = upcomingViewModel.staleMessage {
                NoticeBanner(message: stale, systemImage: "clock.arrow.circlepath", tint: .secondary)
            }

            if upcomingViewModel.isLoading && upcomingViewModel.items.isEmpty {
                upcomingSkeletonList
            } else if let error = upcomingViewModel.errorMessage {
                ErrorStateView(message: error) {
                    await upcomingViewModel.fetch()
                }
                Spacer(minLength: 0)
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
