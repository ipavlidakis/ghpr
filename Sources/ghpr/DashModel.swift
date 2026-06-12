import Foundation
import GithubModule
import Observation

/// The dashboard's state: the repo's open PRs, the active filter, and the
/// action that opens a review window for a selection.
@MainActor
@Observable
final class DashModel {
    let repository: GithubRepository
    private(set) var pullRequests: [GithubPullRequest]
    private(set) var openingNumber: Int?
    var filter: DashFilter = .all
    var errorMessage: String?

    private let client: GithubClient
    private let me: String

    init(repository: GithubRepository, pullRequests: [GithubPullRequest], me: String, client: GithubClient) {
        self.repository = repository
        self.pullRequests = pullRequests
        self.me = me
        self.client = client
    }

    /// Fetches the authenticated user and the repo's open PRs in parallel.
    static func load(with client: GithubClient, repository: GithubRepository) async throws -> DashModel {
        async let user = client.authenticatedUser()
        async let pullRequests = client.openPullRequests(in: repository)
        return DashModel(
            repository: repository,
            pullRequests: try await pullRequests,
            me: try await user.login,
            client: client
        )
    }

    var filtered: [GithubPullRequest] {
        switch filter {
        case .all:
            pullRequests
        case .mine:
            pullRequests.filter { $0.user?.login == me }
        case .reviewRequested:
            pullRequests.filter { pullRequest in
                pullRequest.requestedReviewers.contains { $0.login == me }
            }
        }
    }

    /// Loads the PR and opens its review window in this process.
    func openReview(of pullRequest: GithubPullRequest) async {
        guard openingNumber == nil else { return }
        openingNumber = pullRequest.number
        defer { openingNumber = nil }

        do {
            let reference = GithubPullRequestReference(repository: repository, number: pullRequest.number)
            let data = try await ReviewData.load(with: client, reference: reference)
            AppBootstrap.openWindow(
                title: "\(repository.fullName) #\(pullRequest.number) — \(pullRequest.title)",
                content: ReviewScreen(model: ReviewModel(data: data, client: client))
            )
        } catch {
            errorMessage = "\(error)"
        }
    }

    func reload() async {
        do {
            pullRequests = try await client.openPullRequests(in: repository)
        } catch {
            errorMessage = "\(error)"
        }
    }
}
