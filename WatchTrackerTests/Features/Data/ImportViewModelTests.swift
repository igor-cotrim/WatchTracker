import Foundation
import Testing
@testable import WatchTracker

@Suite("ImportViewModel", .tags(.viewModel, .async), .timeLimit(.minutes(1)))
@MainActor
struct ImportViewModelTests {

    private func makeViewModel(
        batchSize: Int = 100,
        episodeBatchSize: Int = 400
    ) -> (ImportViewModel, MockImportService) {
        let service = MockImportService()
        let viewModel = ImportViewModel(
            service: service,
            batchSize: batchSize,
            episodeBatchSize: episodeBatchSize
        )
        return (viewModel, service)
    }

    // MARK: Episodes

    @Test func `episodes are chunked separately from items`() async {
        let (vm, service) = makeViewModel(batchSize: 2, episodeBatchSize: 3)

        await vm.importBatch(ImportBatch(
            items: TestFixtures.importItems(count: 3),
            episodes: TestFixtures.importEpisodes(count: 7)
        ))

        #expect(service.batchSizes == [2, 1, 0, 0, 0])
        #expect(service.episodeBatchSizes == [0, 0, 3, 3, 1])
    }

    @Test func `an episodes-only batch still uploads`() async {
        let (vm, service) = makeViewModel()

        await vm.importBatch(ImportBatch(episodes: TestFixtures.importEpisodes(count: 5)))

        #expect(vm.errorMessage == nil)
        #expect(service.episodeBatchSizes == [5])
        #expect(vm.result?.episodes == 5)
        #expect(vm.result?.total == 0)
    }

    @Test func `progress reaches 1 across mixed item and episode chunks`() async {
        let (vm, _) = makeViewModel(batchSize: 2, episodeBatchSize: 2)

        await vm.importBatch(ImportBatch(
            items: TestFixtures.importItems(count: 3),
            episodes: TestFixtures.importEpisodes(count: 3)
        ))

        #expect(vm.progress == 1.0)
    }

    // MARK: Empty input

    @Test func `an empty item list reports the empty error and skips the network`() async {
        let (vm, service) = makeViewModel()
        await vm.importBatch(ImportBatch())

        #expect(vm.errorMessage == Strings.Import.errorEmpty)
        #expect(vm.result == nil)
        #expect(vm.isImporting == false)
        #expect(service.importBatchCalls.isEmpty)
    }

    // MARK: Batching

    @Test func `a single batch is sent for fewer items than the batch size`() async {
        let (vm, service) = makeViewModel()
        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 30)))
        #expect(service.batchSizes == [30])
    }

    @Test func `items are split into batches of the configured size`() async {
        let (vm, service) = makeViewModel()
        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 250)))
        #expect(service.batchSizes == [100, 100, 50])
    }

    @Test func `an exact multiple of the batch size does not send a trailing empty batch`() async {
        let (vm, service) = makeViewModel()
        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 200)))
        #expect(service.batchSizes == [100, 100])
    }

    @Test func `batches preserve item order`() async {
        let (vm, service) = makeViewModel(batchSize: 2)
        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 5)))

        let titles = service.importBatchCalls.flatMap { $0.items.map(\.title) }
        #expect(titles == (0..<5).map { "Movie \($0)" })
    }

    // MARK: Summary accumulation

    @Test func `the summary accumulates across batches`() async {
        let (vm, service) = makeViewModel(batchSize: 2)
        service.importBatchResult = { batch in
            .success(TestFixtures.importBatchResult(
                total: batch.items.count,
                matched: batch.items.count,
                watchlist: batch.items.count,
                ratings: 1,
                unmatched: [("Missing \(batch.items.count)", nil)]
            ))
        }

        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 5)))

        let result = vm.result
        #expect(result?.total == 5, "total comes from the input, not the batches")
        #expect(result?.matched == 5)
        #expect(result?.watchlist == 5)
        #expect(result?.ratings == 3, "one per batch, three batches")
        #expect(result?.unmatched.count == 3)
    }

    @Test func `unmatched items are collected in batch order`() async {
        let (vm, service) = makeViewModel(batchSize: 1)
        service.importBatchResult = { batch in
            .success(TestFixtures.importBatchResult(
                total: 1, matched: 0, watchlist: 0, ratings: 0,
                unmatched: [(batch.items[0].title, 2020)]
            ))
        }

        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 3)))
        #expect(vm.result?.unmatched.map(\.title) == ["Movie 0", "Movie 1", "Movie 2"])
    }

    // MARK: Progress

    @Test func `progress reaches exactly 1 when every batch succeeds`() async {
        let (vm, _) = makeViewModel(batchSize: 40)
        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 100)))
        #expect(vm.progress == 1.0)
    }

    @Test func `progress starts at zero for a fresh import`() async {
        let (vm, _) = makeViewModel()
        await vm.importBatch(ImportBatch())
        #expect(vm.progress == 0)
    }

    // MARK: Failures

    @Test func `a failing batch surfaces the error and clears isImporting`() async {
        let (vm, _) = makeViewModel()
        let service = MockImportService()
        service.importBatchError = MockError.generic("boom")
        let failing = ImportViewModel(service: service)

        await failing.importBatch(ImportBatch(items: TestFixtures.importItems(count: 5)))

        #expect(failing.errorMessage != nil)
        #expect(failing.result == nil)
        #expect(failing.isImporting == false)
        _ = vm
    }

    @Test func `a failure mid-run stops sending further batches`() async {
        let service = MockImportService()
        service.importBatchError = MockError.generic("boom")
        let vm = ImportViewModel(service: service, batchSize: 1)

        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 5)))
        #expect(service.importBatchCalls.count == 1)
    }

    @Test func `a new run clears the previous error and result`() async {
        let service = MockImportService()
        service.importBatchError = MockError.generic("boom")
        let vm = ImportViewModel(service: service)

        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 1)))
        #expect(vm.errorMessage != nil)

        service.importBatchError = nil
        await vm.importBatch(ImportBatch(items: TestFixtures.importItems(count: 1)))

        #expect(vm.errorMessage == nil)
        #expect(vm.result != nil)
    }

    // MARK: File reading

    @Test func `importFiles reports an error for an unreadable url`() async {
        let (vm, service) = makeViewModel()
        await vm.importFiles([URL(fileURLWithPath: "/nonexistent/watched.csv")])

        #expect(vm.errorMessage != nil)
        #expect(vm.isImporting == false)
        #expect(service.importBatchCalls.isEmpty)
    }

    @Test func `importFiles parses a real csv and uploads the items`() async throws {
        let (vm, service) = makeViewModel()
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("watched.csv")
        try "Date,Name,Year\n2026-01-01,Dune,2021".write(to: file, atomically: true, encoding: .utf8)

        await vm.importFiles([file])

        #expect(service.importBatchCalls.count == 1)
        #expect(service.importBatchCalls.first?.items.first?.title == "Dune")
        #expect(vm.result?.total == 1)
    }
}
