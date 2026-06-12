/// Persistent storage for the user's GitHub token.
package protocol TokenStore: Sendable {
    func read() async throws -> String?
    func write(_ token: String) async throws
    /// Returns `true` when a stored token was actually removed.
    @discardableResult
    func delete() async throws -> Bool
}
