/// A GitHub account, as embedded in PR and review payloads.
package struct GithubUser: Sendable, Equatable, Hashable, Decodable {
    package let login: String
    package let avatarUrl: String?

    package init(login: String, avatarUrl: String? = nil) {
        self.login = login
        self.avatarUrl = avatarUrl
    }
}
