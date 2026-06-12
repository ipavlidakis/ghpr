import AppKit
import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// Opens the dashboard: open pull requests for the current directory's repo.
struct DashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dash",
        abstract: "Browse the current repository's open pull requests."
    )

    @Flag(help: "Return the terminal immediately; the window keeps running in the background.")
    var detach = false

    func run() throws {
        if detach {
            try Detach.relaunchInBackground()
        }
        let (model, repository) = try AsyncBridge.run { () -> (DashModel, GithubRepository) in
            guard let token = await TokenResolver().resolve() else {
                throw ValidationError("""
                No GitHub token found. To authenticate, either:
                  • run `ghpr auth token` to store a personal access token in the Keychain,
                  • export GHPR_TOKEN or GITHUB_TOKEN, or
                  • sign in to the gh CLI (`gh auth login`) and ghpr will borrow its token.
                """)
            }
            let client = GithubClient(token: token.value)
            let repository = try await LocalRepository().repository()

            print("Loading open pull requests for \(repository.fullName)…")
            return (try await DashModel.load(with: client, repository: repository), repository)
        }

        MainActor.assumeIsolated {
            AppBootstrap.run(
                title: "\(repository.fullName) — open pull requests",
                size: NSSize(width: 780, height: 560),
                content: DashScreen(model: model)
            )
        }
    }
}
