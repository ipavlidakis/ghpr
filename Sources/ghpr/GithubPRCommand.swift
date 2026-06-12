import ArgumentParser

@main
struct GithubPRCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ghpr",
        abstract: "Review GitHub pull requests in a native macOS window, straight from your terminal.",
        version: "0.1.0",
        subcommands: [AuthCommand.self]
    )

    func run() async throws {
        // Until current-directory mode lands (milestone 5), bare `ghpr` shows help.
        throw CleanExit.helpRequest()
    }
}
