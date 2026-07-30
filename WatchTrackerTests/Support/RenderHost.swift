import SwiftUI
import UIKit

/// Instantiates a SwiftUI view and forces its `body` to evaluate.
///
/// Almost every component in this app is a pure function of its inputs — only
/// `SkeletonView` and `WatchlistCardView` have an `onAppear` — so hosting one and
/// laying it out needs no mocks at all. What it catches is real: a force-unwrap in a
/// `body`, a `Config.*` read that traps on a missing Info.plist key, an index crash
/// on an empty fixture, or a layout that never resolves.
///
/// `sizeThatFits(in:)` is what forces the evaluation, and the choice is measured
/// rather than assumed (`RenderStrategyProbe` compared the options on iOS 18):
///
/// | strategy                       | body | onAppear | .task |
/// |--------------------------------|------|----------|-------|
/// | detached + `layoutIfNeeded`    |  no  |    no    |  no   |
/// | `ImageRenderer.uiImage`        | yes  |  **yes** |  no   |
/// | attached to a visible `UIWindow` | yes |  **yes** |  no   |
/// | `sizeThatFits(in:)`, detached  | yes  |    no    |  no   |
///
/// Only the last one evaluates `body` without *appearing* the view, so screens can be
/// rendered without their `.task` reaching the network and without `onAppear` starting
/// an animation. `RenderHostTests` pins all three properties down so a future SDK
/// cannot change them silently.
@MainActor
func render<V: View>(
    _ view: V,
    width: CGFloat = 393,
    height: CGFloat = 852
) -> UIView {
    let host = UIHostingController(rootView: view.transaction { $0.animation = nil })
    _ = host.sizeThatFits(in: CGSize(width: width, height: height))
    host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    return host.view
}

/// Forces a full rasterisation pass, not just layout.
///
/// `render(_:)` evaluates `body`, which is enough for the vast majority of components.
/// It is *not* enough for views whose work happens at draw time — a `Shape.fill` with a
/// gradient, or a `ButtonStyle.makeBody` that only runs once the style is applied to a
/// rendered button. `ImageRenderer` covers those, at the cost of firing `onAppear`.
///
/// Only use it for views with no `.task` and no network: the Unit plan sets
/// `WT_DISABLE_ANIMATIONS=1`, so `MotionPolicy` keeps the two animating components inert
/// even though their `onAppear` now runs. Prefer `render(_:)` everywhere else.
@MainActor
func rasterize<V: View>(_ view: V, width: CGFloat = 393, height: CGFloat = 852) {
    let renderer = ImageRenderer(
        content: view
            .frame(width: width, height: height)
            .transaction { $0.animation = nil }
    )
    _ = renderer.uiImage
}

// Deliberately no accessibility-tree helper here. A detached `_UIHostingView` reports
// `accessibilityElements == []` and has no subviews — SwiftUI only materialises its
// accessibility tree once the view joins a window, which is exactly what fires
// `onAppear` and `.task`. Asserting composed a11y labels would therefore cost the one
// property that makes this file useful. Where the *content* of a label matters, extract
// the composition into a plain function and test that instead of the rendered tree.
