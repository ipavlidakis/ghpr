import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// Lists open pull requests for the current directory's repo.
struct DashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dash",
        abstract: "List open pull requests for the current repository."
    )

    func run() throws {
        let (pullRequests, repository) = try AsyncBridge.run { () -> ([GithubPullRequest], GithubRepository) in
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
            return (try await client.openPullRequests(in: repository), repository)
        }

        if pullRequests.isEmpty {
            print("No open pull requests found for \(repository.fullName).")
            return
        }

        print("Open pull requests for \(repository.fullName):")
        for pullRequest in pullRequests {
            print("  #\(pullRequest.number) [\(pullRequest.state)] \(pullRequest.title)")
            print("    URL: \(pullRequest.htmlUrl)")
        }
    }
}
