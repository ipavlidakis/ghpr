import Foundation

/// One commit of a pull request.
package struct GithubCommit: Sendable, Equatable, Decodable {
    package let sha: String
    private let commit: Body
    private let author: Account?

    private struct Body: Decodable, Equatable, Sendable {
        struct Meta: Decodable, Equatable, Sendable {
            let name: String?
            let date: Date?
        }

        let message: String
        let author: Meta?
    }

    private struct Account: Decodable, Equatable, Sendable {
        let login: String
    }

    /// The first line of the commit message.
    package var summary: String {
        commit.message.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? commit.message
    }

    package var authorName: String? {
        author?.login ?? commit.author?.name
    }

    package var authoredAt: Date? {
        commit.author?.date
    }

    package var shortSha: String {
        String(sha.prefix(7))
    }
}
