import Foundation

/// The network seam of `GithubClient`; tests substitute a stub.
package protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
