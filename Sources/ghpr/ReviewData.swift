import Foundation
import GithubModule

/// All pull request data needed for CLI summaries, fetched in parallel.
struct ReviewData: Sendable {
    let reference: GithubPullRequestReference
    let pullRequest: GithubPullRequest
    let files: [FileDiff]
    let checkRuns: [GithubCheckRun]
    let threads: [GithubReviewThread]
    let commits: [GithubCommit]
    let timeline: [GithubTimelineItem]

    static func load(with client: GithubClient, reference: GithubPullRequestReference) async throws -> ReviewData {
        async let pullRequest = client.pullRequest(in: reference.repository, number: reference.number)
        async let diff = client.diff(in: reference.repository, number: reference.number)
        async let threads = client.reviewThreads(in: reference.repository, number: reference.number)
        async let commits = client.commits(in: reference.repository, number: reference.number)
        async let timeline = client.timeline(in: reference.repository, number: reference.number)

        let resolved = try await pullRequest
        let checkRuns = try await client.checkRuns(in: reference.repository, ref: resolved.head.sha)

        return ReviewData(
            reference: reference,
            pullRequest: resolved,
            files: UnifiedDiffParser().parse(try await diff),
            checkRuns: checkRuns,
            threads: try await threads,
            commits: try await commits,
            timeline: try await timeline
        )
    }

    func printSummary() {
        print("Repository: \(reference.repository.fullName) #\(reference.number)")
        print("Title: \(pullRequest.title)")
        print("State: \(pullRequest.state)")
        print("URL: \(pullRequest.htmlUrl)")
        print("Files: \(files.count)")
        print("Commits: \(commits.count)")
        print("Checks: \(checkRuns.count)")
        print("Timeline entries: \(timeline.count)")
        print("Threads: \(threads.count)")
    }
}
