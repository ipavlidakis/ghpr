import Foundation

/// One reaction kind on a comment, with how many people used it.
package struct GithubReaction: Sendable, Equatable {
    package let content: GithubReactionContent
    package let count: Int

    package init(content: GithubReactionContent, count: Int) {
        self.content = content
        self.count = count
    }
}
