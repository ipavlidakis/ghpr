import Foundation
import Testing
import GithubModule

/// Covers PR URL parsing forms and rejections.
@Suite("GithubPullRequestReference")
struct GithubPullRequestReferenceTests {
    private let expected = GithubPullRequestReference(
        repository: GithubRepository(owner: "apple", name: "swift-argument-parser"),
        number: 908
    )

    @Test(
        "recognized URL forms",
        arguments: [
            "https://github.com/apple/swift-argument-parser/pull/908",
            "https://github.com/apple/swift-argument-parser/pull/908/files",
            "https://github.com/apple/swift-argument-parser/pull/908#discussion_r123",
            "https://github.com/apple/swift-argument-parser/pull/908?diff=split",
            "  https://github.com/apple/swift-argument-parser/pull/908\n"
        ]
    )
    func parses(url: String) {
        #expect(GithubPullRequestReference(url: url) == expected)
    }

    @Test(
        "rejected URL forms",
        arguments: [
            "https://github.com/apple/swift-argument-parser",
            "https://github.com/apple/swift-argument-parser/issues/908",
            "https://github.com/apple/swift-argument-parser/pull/not-a-number",
            "https://github.com/apple/swift-argument-parser/pull/0",
            "not a url at all",
            ""
        ]
    )
    func rejects(url: String) {
        #expect(GithubPullRequestReference(url: url) == nil)
    }
}
