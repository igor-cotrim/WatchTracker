import Foundation

/// A `Clock` that never actually sleeps, so debounce and retry paths run instantly.
/// Records every requested duration so tests can assert on the delay that was asked for.
final class ImmediateClock: Clock, @unchecked Sendable {
    struct Instant: InstantProtocol {
        var offset: Duration = .zero

        func advanced(by duration: Duration) -> Instant { Instant(offset: offset + duration) }
        func duration(to other: Instant) -> Duration { other.offset - offset }
        static func < (lhs: Instant, rhs: Instant) -> Bool { lhs.offset < rhs.offset }
    }

    private let lock = NSLock()
    private var _now = Instant()
    private var _sleeps: [Duration] = []

    /// Durations passed to `sleep`, in call order.
    var sleeps: [Duration] { lock.withLock { _sleeps } }

    var now: Instant { lock.withLock { _now } }
    var minimumResolution: Duration { .zero }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        try Task.checkCancellation()
        lock.withLock {
            _sleeps.append(_now.duration(to: deadline))
            _now = deadline
        }
        // Give cancellation and other tasks a chance to interleave, as a real sleep would.
        await Task.yield()
        try Task.checkCancellation()
    }
}
