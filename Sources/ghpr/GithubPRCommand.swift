import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// The `ghpr` entry point: opens a review window for a PR URL, or for the
/// open PR of the current directory's branch when no URL is given.
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
        subcommands: [AuthCommand.self, DemoCommand.self]
    )

    @Argument(help: "A pull request URL (https://github.com/owner/repo/pull/123). Omit to use the current directory's branch.")
    var pullRequestURL: String?

    func run() throws {
        let urlArgument = pullRequestURL

        let data = try AsyncBridge.run {
            guard let token = await TokenResolver().resolve() else {
                throw ValidationError("""
                No GitHub token found. To authenticate, either:
                  • run `ghpr auth token` to store a personal access token in the Keychain,
                  • export GHPR_TOKEN or GITHUB_TOKEN, or
                  • sign in to the gh CLI (`gh auth login`) and ghpr will borrow its token.
                """)
            }
            let client = GithubClient(token: token.value)
            let reference = try await Self.resolveReference(urlArgument: urlArgument, client: client)
            print("Loading \(reference.repository.fullName) #\(reference.number)…")
            return try await ReviewData.load(with: client, reference: reference)
        }

        MainActor.assumeIsolated {
            AppBootstrap.run(
                title: "\(data.reference.repository.fullName) #\(data.reference.number) — \(data.pullRequest.title)",
                content: ReviewScreen(data: data)
            )
        }
    }

    /// URL argument if present, otherwise current-directory mode:
    /// origin remote → current branch → open PR for `owner:branch`.
    private static func resolveReference(
        urlArgument: String?,
        client: GithubClient
    ) async throws -> GithubPullRequestReference {
        if let urlArgument {
            guard let reference = GithubPullRequestReference(url: urlArgument) else {
                throw ValidationError("""
                Not a pull request URL: \(urlArgument)
                Expected the form https://github.com/{owner}/{repo}/pull/{number}
                """)
            }
            return reference
        }

        let localRepository = LocalRepository()
        let repository = try await localRepository.repository()
        let branch = try await localRepository.currentBranch()
        guard let pullRequest = try await client.openPullRequest(in: repository, branch: branch) else {
            throw ValidationError("""
            No open pull request found for \(repository.fullName) branch '\(branch)'.
            Once `ghpr dash` ships (milestone 7) you will be able to browse all open PRs.
            """)
        }
        return GithubPullRequestReference(repository: repository, number: pullRequest.number)
    }
}
