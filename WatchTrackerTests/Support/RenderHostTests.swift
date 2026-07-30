import SwiftUI
import Testing
@testable import WatchTracker

/// Pins down the three properties `render(_:)` depends on. They are assumptions about
/// SwiftUI's lifecycle rather than about our code, so they are worth asserting
/// directly: if a future SDK changes any of them, every view test built on
/// `render(_:)` starts behaving differently, and this suite is what says so.
@MainActor
@Suite("render(_:)", .tags(.view, .pure))
struct RenderHostTests {

    /// Records which lifecycle hooks ran. A class so the view can stay a value type.
    private final class Trace {
        var bodyEvaluated = false
        var appeared = false
        var taskRan = false
    }

    private struct Probe: View {
        let trace: Trace

        var body: some View {
            trace.bodyEvaluated = true
            return Text(verbatim: "probe")
                .onAppear { trace.appeared = true }
                .task { trace.taskRan = true }
        }
    }

    @Test func `evaluates body during layout`() {
        let trace = Trace()
        _ = render(Probe(trace: trace))
        #expect(trace.bodyEvaluated, "body never ran — nothing would be covered")
    }

    /// The load-bearing assumption. A detached `UIHostingController` never appears, so
    /// screens can be rendered without their `.task` reaching the network — which is
    /// what lets us cover production screens without adding injection seams to them.
    @Test func `does not appear the view or fire its task`() {
        let trace = Trace()
        _ = render(Probe(trace: trace))
        #expect(trace.appeared == false, "onAppear fired — screens would run their .task")
        #expect(trace.taskRan == false, ".task fired — screens would hit the network")
    }

    @Test func `lays the hosted view out at the requested size`() {
        let view = render(Text(verbatim: "sized"), width: 320, height: 480)
        #expect(view.bounds.width == 320)
        #expect(view.bounds.height == 480)
    }

}
