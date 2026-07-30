import Foundation

/// Whether the app should run its decorative, indefinite animations.
///
/// Two components animate forever once they appear — `SkeletonView`'s shimmer and
/// `WatchlistCardView`'s badge entrance. Neither ever settles, which makes any
/// rendered or captured view non-deterministic: the frame you get depends on when
/// you looked. Snapshot and UI-test harnesses set `WT_DISABLE_ANIMATIONS=1` so
/// those views render their resting state instead.
///
/// Resolved once as a `static let`: Swift Testing runs tests in parallel in-process,
/// so a mutable global here would race. It is never set in a shipping build.
enum MotionPolicy {
    static let isEnabled = ProcessInfo.processInfo.environment["WT_DISABLE_ANIMATIONS"] != "1"
}
