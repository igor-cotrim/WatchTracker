import Foundation

/// Intercepts requests for a `URLSession` built from `StubURLProtocol.session()`.
///
/// Handlers are keyed by session configuration rather than registered globally, so
/// parallel suites never see each other's stubs.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {

    struct Stub {
        var statusCode: Int
        var body: Data
        var headers: [String: String]
        /// When set, the request fails at the transport with this code instead of answering.
        /// The only way to exercise the offline paths, which are about requests that never
        /// reach a server rather than servers that answer badly.
        var failure: URLError.Code?

        init(
            statusCode: Int = 200,
            body: Data = Data("{}".utf8),
            headers: [String: String] = [:],
            failure: URLError.Code? = nil
        ) {
            self.statusCode = statusCode
            self.body = body
            self.headers = headers
            self.failure = failure
        }

        static func json(_ string: String, statusCode: Int = 200) -> Stub {
            Stub(statusCode: statusCode, body: Data(string.utf8))
        }

        /// A request that never lands — a dropped connection, a timeout, no route at all.
        static func failing(_ code: URLError.Code) -> Stub {
            Stub(failure: code)
        }
    }

    /// Per-session recording of the requests that were issued and the stubs to return.
    final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stubs: [Stub]
        private var _requests: [URLRequest] = []

        /// Stubs are consumed in order; the last one repeats once exhausted.
        init(_ stubs: [Stub]) {
            precondition(!stubs.isEmpty, "Provide at least one stub")
            self.stubs = stubs
        }

        var requests: [URLRequest] {
            lock.withLock { _requests }
        }

        var requestCount: Int { requests.count }

        /// `URLSession` converts `httpBody` into `httpBodyStream` before the protocol
        /// sees the request, so read whichever one is populated.
        func body(at index: Int = 0) -> Data? {
            guard let request = requests.indices.contains(index) ? requests[index] : nil else { return nil }
            if let body = request.httpBody { return body }
            guard let stream = request.httpBodyStream else { return nil }

            stream.open()
            defer { stream.close() }

            var data = Data()
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                guard read > 0 else { break }
                data.append(buffer, count: read)
            }
            return data
        }

        fileprivate func next(for request: URLRequest) -> Stub {
            lock.withLock {
                _requests.append(request)
                return stubs.count > 1 ? stubs.removeFirst() : stubs[0]
            }
        }
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var recorders: [String: Recorder] = [:]

    /// Builds an ephemeral session wired to `stubs` and returns it with its recorder.
    static func session(_ stubs: [Stub]) -> (URLSession, Recorder) {
        let recorder = Recorder(stubs)
        let token = UUID().uuidString

        lock.withLock { recorders[token] = recorder }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        config.httpAdditionalHeaders = ["X-Stub-Token": token]
        return (URLSession(configuration: config), recorder)
    }

    static func session(_ stub: Stub) -> (URLSession, Recorder) {
        session([stub])
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: "X-Stub-Token") != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let token = request.value(forHTTPHeaderField: "X-Stub-Token"),
              let recorder = StubURLProtocol.lock.withLock({ StubURLProtocol.recorders[token] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let stub = recorder.next(for: request)

        if let failure = stub.failure {
            client?.urlProtocol(self, didFailWithError: URLError(failure))
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
