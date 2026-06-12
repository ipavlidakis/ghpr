@testable import AuthenticationModule

/// Test double for `TokenStore`, tracking reads and optionally failing them.
actor InMemoryTokenStore: TokenStore {
    private var token: String?
    private let readError: KeychainError?
    private(set) var readCount = 0

    init(token: String? = nil, readError: KeychainError? = nil) {
        self.token = token
        self.readError = readError
    }

    func read() throws -> String? {
        readCount += 1
        if let readError { throw readError }
        return token
    }

    func write(_ token: String) {
        self.token = token
    }

    @discardableResult
    func delete() -> Bool {
        defer { token = nil }
        return token != nil
    }
}
