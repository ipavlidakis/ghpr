import Foundation
import Testing
@testable import AuthenticationModule

/// Exercises the real macOS Keychain with a test-only service and a unique
/// account per test, so user data is never touched and tests stay independent.
@Suite("KeychainTokenStore")
struct KeychainTokenStoreTests {
    private let store = KeychainTokenStore(service: "ghpr.tests", account: UUID().uuidString)

    @Test("write then read round-trips the token")
    func roundTrip() async throws {
        try await store.write("secret-token")
        #expect(try await store.read() == "secret-token")
        try await store.delete()
    }

    @Test("writing twice overwrites the stored token")
    func overwrite() async throws {
        try await store.write("first")
        try await store.write("second")
        #expect(try await store.read() == "second")
        try await store.delete()
    }

    @Test("reading a missing token returns nil")
    func readMissing() async throws {
        #expect(try await store.read() == nil)
    }

    @Test("delete removes the token and reports whether anything was deleted")
    func delete() async throws {
        try await store.write("doomed")

        #expect(try await store.delete() == true)
        #expect(try await store.read() == nil)
        #expect(try await store.delete() == false)
    }
}
