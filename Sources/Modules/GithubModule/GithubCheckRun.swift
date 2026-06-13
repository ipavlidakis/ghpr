import Foundation

/// A single CI check run for a commit.
package struct GithubCheckRun: Sendable, Equatable, Decodable {
    package let name: String
    /// `queued`, `in_progress`, or `completed`.
    package let status: String
    /// Set once completed: `success`, `failure`, `neutral`, `cancelled`, `skipped`, `timed_out`, or `action_required`.
    package let conclusion: String?
    package let htmlUrl: String?
}
