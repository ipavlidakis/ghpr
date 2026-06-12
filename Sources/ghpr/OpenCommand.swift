import AppKit
import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// The default command: opens a review window for a PR URL, or for the open
/// PR of the current directory's branch — falling back to the dashboard
/// when the branch has no open PR.
struct OpenCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open a review window for a pull request."
    )

    @Argument(help: "A pull request URL (https://github.com/owner/repo/pull/123). Omit to use the current directory's branch.")
    var pullRequestURL: String?

    /// Where the command ends up once the network work is done.
    private enum Destination: Sendable {
        case review(ReviewData, GithubClient)
        case dash(DashModel)
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
                return .review(try await ReviewData.load(with: client, reference: reference), client)
            }

            let localRepository = LocalRepository()
            let repository = try await localRepository.repository()
            let branch = try await localRepository.currentBranch()

            if let pullRequest = try await client.openPullRequest(in: repository, branch: branch) {
                let reference = GithubPullRequestReference(repository: repository, number: pullRequest.number)
                print("Loading \(reference.repository.fullName) #\(reference.number)…")
                return .review(try await ReviewData.load(with: client, reference: reference), client)
            }

            print("No open pull request for branch '\(branch)' — opening the dashboard…")
            return .dash(try await DashModel.load(with: client, repository: repository))
        }

        MainActor.assumeIsolated {
            switch destination {
            case .review(let data, let client):
                AppBootstrap.run(
                    title: "\(data.reference.repository.fullName) #\(data.reference.number) — \(data.pullRequest.title)",
                    content: ReviewScreen(model: ReviewModel(data: data, client: client))
                )
            case .dash(let model):
                AppBootstrap.run(
                    title: "\(model.repository.fullName) — open pull requests",
                    size: NSSize(width: 780, height: 560),
                    content: DashScreen(model: model)
                )
            }
        }
    }
}
