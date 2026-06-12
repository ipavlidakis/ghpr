/// Envelope of the check-runs REST endpoint.
package struct GithubCheckRunsResponse: Sendable, Decodable {
    package let totalCount: Int
    package let checkRuns: [GithubCheckRun]
}
