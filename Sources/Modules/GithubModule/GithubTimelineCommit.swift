import Foundation

/// A commit pushed to the pull request branch, as it appears in the timeline.
package struct GithubTimelineCommit: Sendable, Equatable {
    package let sha: String
    package let message: String
    package let authorName: String?
    package let date: Date?

    package init(sha: String, message: String, authorName: String? = nil, date: Date? = nil) {
        self.sha = sha
        self.message = message
        self.authorName = authorName
        self.date = date
    }
}
