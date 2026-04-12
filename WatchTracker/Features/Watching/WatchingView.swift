import SwiftUI

private enum WatchingTab {
    case watching, upcoming
}

struct WatchingView: View {
    @State private var viewModel = ContinueWatchingViewModel()
    @State private var upcomingViewModel = UpcomingViewModel()
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
                        Label("Ver detalhes", systemImage: "info.circle")
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
                    upcomingSectionHeader(for: section.sectionKey)
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

    private func upcomingSectionHeader(for key: String) -> some View {
        let label: String = {
            switch key {
            case "today":    return Strings.Upcoming.today
            case "tomorrow": return Strings.Upcoming.tomorrow
            case "later":    return Strings.Upcoming.later
            default:         return key.uppercased()
            }
        }()
        return Text(label)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 6)
    }
}

// MARK: - WatchingRow

private struct WatchingRow: View {
    let item: ContinueWatchingItem
    let onMarkWatched: () async -> Void

    @State private var isMarking = false

    var body: some View {
        ZStack {
            NavigationLink {
                MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
            } label: {
                EmptyView()
            }
            .opacity(0)

            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(1)

                if let next = item.nextEpisode {
                    Text(verbatim: Strings.Watching.episodeLabel(season: next.seasonNumber, episode: next.episodeNumber))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(verbatim: next.name)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                guard !isMarking else { return }
                Task {
                    isMarking = true
                    await onMarkWatched()
                    isMarking = false
                }
            } label: {
                ZStack {
                    if isMarking {
                        ProgressView()
                            .tint(Color.brandPrimary)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.brandPrimary, Color.brandPrimary.opacity(0.15))
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(width: 28, height: 28)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isMarking)
            }
            .buttonStyle(.plain)
            .disabled(isMarking)
            .sensoryFeedback(.success, trigger: isMarking)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var thumbnail: some View {
        AsyncImage(url: item.stillURL ?? item.posterURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                SkeletonView()
            }
        }
        .frame(width: 120, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
        .overlay(alignment: .bottomLeading) {
            Image(systemName: "play.fill")
                .font(.caption2)
                .foregroundStyle(.white)
                .padding(6)
        }
    }
}

// MARK: - UpcomingRow

private struct UpcomingRow: View {
    let item: UpcomingItem

    var body: some View {
        ZStack {
            NavigationLink {
                MediaDetailView(mediaType: .tv, mediaId: item.tmdbId)
            } label: {
                EmptyView()
            }
            .opacity(0)

            HStack(spacing: 14) {
                poster

                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: item.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .lineLimit(1)

                    Text(verbatim: Strings.Watching.episodeLabel(
                        season: item.nextEpisode.seasonNumber,
                        episode: item.nextEpisode.episodeNumber
                    ))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                    Text(verbatim: item.nextEpisode.name)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                airDateIndicator
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
    }

    private var poster: some View {
        AsyncImage(url: item.posterURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                SkeletonView()
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var airDateIndicator: some View {
        let days = item.nextEpisode.daysUntilAir
        let provider = item.watchProviders.first

        VStack(alignment: .trailing, spacing: 4) {
            if let provider {
                Text(provider)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            switch days {
            case 0:
                Text(Strings.Upcoming.today)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary, in: Capsule())

            case 1:
                Text(Strings.Upcoming.tomorrow)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange, in: Capsule())

            default:
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text(Strings.Upcoming.daysAway(days).components(separatedBy: " ").last ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
        }
        .frame(minWidth: 52, alignment: .trailing)
    }
}

// MARK: - Skeleton

private struct WatchingRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonView()
                .frame(width: 120, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView()
                    .frame(width: 80, height: 10)
                    .clipShape(Capsule())
                SkeletonView()
                    .frame(width: 120, height: 14)
                    .clipShape(Capsule())
                SkeletonView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 10)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 28, height: 28)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
