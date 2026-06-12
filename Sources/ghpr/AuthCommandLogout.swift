import ArgumentParser
import AuthenticationModule

extension AuthCommand {
    /// Removes the stored token from the macOS Keychain.
    struct Logout: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "logout",
            abstract: "Remove the stored token from the macOS Keychain."
        )

        func run() async throws {
            if try await KeychainTokenStore().delete() {
                print("Removed the GitHub token from the macOS Keychain.")
            } else {
                print("No GitHub token was stored in the macOS Keychain.")
            }
        }
    }
}
