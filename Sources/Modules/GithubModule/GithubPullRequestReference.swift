import Foundation

/// A pull request identified by repository and number, parsed from a URL.
package struct GithubPullRequestReference: Sendable, Equatable {
    package let repository: GithubRepository
    package let number: Int

    package init(repository: GithubRepository, number: Int) {
        self.repository = repository
        self.number = number
    }

    /// Parses `https://github.com/{owner}/{repo}/pull/{number}`, tolerating
    /// trailing segments (`/files`), fragments, and query parameters.
    package init?(url: String) {
        guard let components = URLComponents(string: url.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        let path = components.path.split(separator: "/")
        guard
            path.count >= 4,
            path[2] == "pull",
            let number = Int(path[3]),
            number > 0
        else { return nil }

        self.init(
            repository: GithubRepository(owner: String(path[0]), name: String(path[1])),
            number: number
        )
    }
}
