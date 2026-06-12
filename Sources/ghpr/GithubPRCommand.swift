import ArgumentParser
import Foundation

/// The `ghpr` entry point: routes to subcommands, defaulting to `open` so
/// both `ghpr <pr-url>` and bare `ghpr` open a review window.
///
/// Deliberately a synchronous `ParsableCommand`: UI commands hand the main
/// thread to AppKit, which requires the standard (non-async) main. Async
/// work goes through `AsyncBridge`.
@main
struct GithubPRCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ghpr",
        abstract: "Review GitHub pull requests in a native macOS window, straight from your terminal.",
        version: "0.1.0",
        subcommands: [OpenCommand.self, AuthCommand.self, DemoCommand.self],
        defaultSubcommand: OpenCommand.self
    )
}
