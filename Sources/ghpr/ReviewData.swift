import DiffUIModule
import Foundation
import GithubModule

/// Everything the review window shows, fetched in parallel.
struct ReviewData: Sendable {
    let reference: GithubPullRequestReference
    let pullRequest: GithubPullRequest
    let files: [FileDiff]
    let checkRuns: [GithubCheckRun]
    let threads: [GithubReviewThread]

    static func load(with client: GithubClient, reference: GithubPullRequestReference) async throws -> ReviewData {
        async let pullRequest = client.pullRequest(in: reference.repository, number: reference.number)
        async let diff = client.diff(in: reference.repository, number: reference.number)
        async let threads = client.reviewThreads(in: reference.repository, number: reference.number)

        let resolved = try await pullRequest
        let checkRuns = try await client.checkRuns(in: reference.repository, ref: resolved.head.sha)

        return ReviewData(
            reference: reference,
            pullRequest: resolved,
            files: UnifiedDiffParser().parse(try await diff),
            checkRuns: checkRuns,
            threads: try await threads
        )
    }
}
