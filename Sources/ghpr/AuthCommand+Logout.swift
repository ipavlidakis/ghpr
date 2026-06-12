import ArgumentParser
import AuthenticationModule
import Foundation

/// The `ghpr auth logout` subcommand.
extension AuthCommand {
    /// Removes the stored token from the macOS Keychain.
    struct Logout: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "logout",
            abstract: "Remove the stored token from the macOS Keychain."
        )

        func run() throws {
            let removed = try AsyncBridge.run {
                try await KeychainTokenStore().delete()
            }
            if removed {
                print("Removed the GitHub token from the macOS Keychain.")
            } else {
                print("No GitHub token was stored in the macOS Keychain.")
            }
        }
    }
}
