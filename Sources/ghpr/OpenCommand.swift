import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// The default command: prints a pull request summary for a PR URL, or for the
/// open PR of the current directory's branch. When no branch PR exists, prints
/// the repo's open pull request list.
struct OpenCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Show a pull request summary from the terminal."
    )

    @Argument(help: "A pull request URL (https://github.com/owner/repo/pull/123). Omit to use the current directory's branch.")
    var pullRequestURL: String?

    /// Where the command ends up once the network work is done.
    private enum Destination: Sendable {
        case review(ReviewData)
        case dash([GithubPullRequest], GithubRepository)
    }

    func run() throws {
        let urlArgument = pullRequestURL

        let destination = try AsyncBridge.run { () -> Destination in
            guard let token = await TokenResolver().resolve() else {
                throw ValidationError("""
                No GitHub token found. To authenticate, either:
                  • run `ghpr auth token` to store a personal access token in the Keychain,
                  • export GHPR_TOKEN or GITHUB_TOKEN, or
                  • sign in to the gh CLI (`gh auth login`) and ghpr will borrow its token.
                """)
            }
            let client = GithubClient(token: token.value)

            if let urlArgument {
                guard let reference = GithubPullRequestReference(url: urlArgument) else {
                    throw ValidationError("""
                    Not a pull request URL: \(urlArgument)
                    Expected the form https://github.com/{owner}/{repo}/pull/{number}
                    """)
                }
                print("Loading \(reference.repository.fullName) #\(reference.number)…")
                return .review(try await ReviewData.load(with: client, reference: reference))
            }

            let localRepository = LocalRepository()
            let repository = try await localRepository.repository()
            let branch = try await localRepository.currentBranch()

            if let pullRequest = try await client.openPullRequest(in: repository, branch: branch) {
                let reference = GithubPullRequestReference(repository: repository, number: pullRequest.number)
                print("Loading \(reference.repository.fullName) #\(reference.number)…")
                return .review(try await ReviewData.load(with: client, reference: reference))
            }

            let openPullRequests = try await client.openPullRequests(in: repository)
            print("No open pull request for branch '\(branch)' in \(repository.fullName).")
            return .dash(openPullRequests, repository)
        }

        switch destination {
        case .review(let data):
            printPullRequestSummary(data)
        case .dash(let pullRequests, let repository):
            printOpenPullRequests(pullRequests, repository: repository)
        }
    }

    private func printPullRequestSummary(_ data: ReviewData) {
        print("Pull request summary:")
        data.printSummary()
    }

    private func printOpenPullRequests(_ pullRequests: [GithubPullRequest], repository: GithubRepository) {
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
