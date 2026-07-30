import SwiftUI
import Testing
@testable import WatchTracker

/// Renders every component in the global `Components/` folder in each state a caller can
/// put it in. These views were at 0% coverage: nothing had ever evaluated their `body`.
///
/// The assertion is deliberately weak — a laid-out, non-empty view — because the value
/// is in the execution, not the measurement. Evaluating `body` is what surfaces a
/// force-unwrap, a trapping `Config` read, or an index crash on an empty collection.
/// Anything about *appearance* belongs in a snapshot test, and anything about composed
/// text belongs in a test of the function that composes it.
///
/// Poster URLs are nil throughout, so `AsyncImage` takes its local placeholder branch
/// and no test reaches image.tmdb.org.
@MainActor
@Suite("Global components render", .tags(.view, .pure))
struct GlobalComponentRenderTests {

    // MARK: - PosterCardView

    @Test(arguments: [
        ("Fight Club", CGFloat(120)),
        ("A Very Long Title That Has To Wrap Onto Two Lines", CGFloat(120)),
        ("Narrow", CGFloat(80))
    ])
    func `poster card renders at any width`(title: String, width: CGFloat) {
        let view = render(PosterCardView(url: nil, title: title, width: width), width: 200, height: 260)
        #expect(view.bounds.width == 200)
    }

    // MARK: - SkeletonView

    /// Rasterised rather than laid out: the shimmer is a gradient `fill`, so its work
    /// happens at draw time. The Unit plan sets `WT_DISABLE_ANIMATIONS=1`, which keeps
    /// `MotionPolicy` from starting the never-ending `repeatForever` animation.
    @Test func `skeleton renders its resting gradient`() {
        rasterize(SkeletonView(), width: 120, height: 180)
        #expect(MotionPolicy.isEnabled == false, "the Unit plan must disable animations")
    }

    // MARK: - ErrorStateView

    @Test func `error state renders without a retry action`() {
        let view = render(ErrorStateView(message: "Something went wrong"))
        #expect(view.bounds.width == 393)
    }

    @Test func `error state renders with a retry action`() {
        let view = render(ErrorStateView(message: "Something went wrong", retryAction: {}))
        #expect(view.bounds.width == 393)
    }

    // MARK: - SectionHeaderView

    @Test func `section header renders title only`() {
        let view = render(SectionHeaderView(title: "Trending"), height: 60)
        #expect(view.bounds.height == 60)
    }

    @Test func `section header renders with a see-all destination`() {
        let view = render(
            SectionHeaderView(
                title: "Trending",
                seeAllTitle: "See all",
                seeAllDestination: { Text(verbatim: "destination") }
            ),
            height: 60
        )
        #expect(view.bounds.height == 60)
    }

    // MARK: - MediaRowSection

    @Test func `media row section renders a populated row`() {
        let items = (1...4).map { TestFixtures.mediaDetail(id: $0, posterPath: nil, backdropPath: nil) }
        let view = render(MediaRowSection(title: "Trending", items: items), height: 300)
        #expect(view.bounds.height == 300)
    }

    /// An empty row is the state a failed or still-loading fetch produces, and it is the
    /// one most likely to trip an index assumption.
    @Test func `media row section renders an empty row`() {
        let view = render(MediaRowSection(title: "Trending", items: []), height: 300)
        #expect(view.bounds.height == 300)
    }

    // MARK: - PressedButtonStyle

    /// `makeBody` only runs once the styled button is actually drawn, so this one needs
    /// rasterising too.
    @Test func `pressed button style applies to a button`() {
        rasterize(
            Button { } label: { Text(verbatim: "Tap") }
                .buttonStyle(PressedButtonStyle()),
            width: 200,
            height: 60
        )
    }
}
