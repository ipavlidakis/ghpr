import ArgumentParser
import Foundation

/// Groups the token-management subcommands: `token`, `status`, `logout`.
struct AuthCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Manage the GitHub token ghpr uses.",
        subcommands: [Token.self, Status.self, Logout.self]
    )
}
