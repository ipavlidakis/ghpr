import ArgumentParser
import Foundation

/// The `ghpr` entry point: routes to subcommands, defaulting to `open` so
/// both `ghpr <pr-url>` and bare `ghpr` print a pull request summary.
///
/// Deliberately a synchronous `ParsableCommand` so CLI startup stays simple.
@main
struct GithubPRCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ghpr",
        abstract: "Review GitHub pull requests from the terminal.",
        version: "0.3.1",
        subcommands: [OpenCommand.self, DashCommand.self, AuthCommand.self, DemoCommand.self],
        defaultSubcommand: OpenCommand.self
    )
}
