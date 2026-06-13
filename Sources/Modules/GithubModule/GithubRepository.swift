import Foundation

/// A GitHub repository identified by owner and name.
package struct GithubRepository: Sendable, Equatable, Hashable {
    package let owner: String
    package let name: String

    package init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }

    package var fullName: String { "\(owner)/\(name)" }
}
