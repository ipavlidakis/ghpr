/// The minimal repository payload embedded in a branch reference.
package struct GithubRepoSummary: Sendable, Equatable, Decodable {
    package let fullName: String

    package init(fullName: String) {
        self.fullName = fullName
    }
}
