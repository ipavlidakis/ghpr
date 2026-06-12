/// One side of a pull request: branch name, commit, and owning repository.
package struct GithubBranchRef: Sendable, Equatable, Decodable {
    package let ref: String
    package let sha: String
    /// `nil` when the source repository (a fork) has been deleted.
    package let repo: GithubRepoSummary?

    package init(ref: String, sha: String, repo: GithubRepoSummary? = nil) {
        self.ref = ref
        self.sha = sha
        self.repo = repo
    }
}
