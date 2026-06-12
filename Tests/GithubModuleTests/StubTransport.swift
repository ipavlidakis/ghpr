import Foundation
import GithubModule

/// Scripted `HTTPTransport` that replays queued responses and records every request.
actor StubTransport: HTTPTransport {
    struct Stub {
        let data: Data
        let statusCode: Int
        let headers: [String: String]

        init(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
        }
    }

    struct NoStubbedResponse: Error {}

    private var stubs: [Stub]
    private(set) var requests: [URLRequest] = []

    init(stubs: [Stub]) {
        self.stubs = stubs
    }

    init(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
        self.init(stubs: [Stub(data: data, statusCode: statusCode, headers: headers)])
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard !stubs.isEmpty else { throw NoStubbedResponse() }

        let stub = stubs.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: stub.headers
        )!
        return (stub.data, response)
    }
}
