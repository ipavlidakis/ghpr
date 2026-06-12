import ArgumentParser
import Foundation

/// The `ghpr` entry point: parses the CLI surface and routes to subcommands.
///
/// Deliberately a synchronous `ParsableCommand`: UI commands hand the main
/// thread to AppKit, which requires the standard (non-async) main. Async
/// work in subcommands goes through `AsyncBridge`.
@main
struct GithubPRCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ghpr",
        abstract: "Review GitHub pull requests in a native macOS window, straight from your terminal.",
        version: "0.1.0",
        subcommands: [AuthCommand.self, DemoCommand.self]
    )

    func run() throws {
        // Until current-directory mode lands (milestone 5), bare `ghpr` shows help.
        throw CleanExit.helpRequest()
    }
}
