import Foundation
import Testing
import GithubModule

/// Verifies write-path request construction against scripted transports.
@Suite("GithubClient write path")
struct GithubClientWritePathTests {
    private let repository = GithubRepository(owner: "ipavlidakis", name: "ghpr")

    private func client(_ transport: StubTransport) -> GithubClient {
        GithubClient(token: "test-token", transport: transport)
    }

    private func body(of request: URLRequest) throws -> [String: Any] {
        let data = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("submitReview posts the verdict, summary, and batched comments")
    func submitReview() async throws {
        let transport = StubTransport(data: Data("{}".utf8))

        try await client(transport).submitReview(
            in: repository,
            number: 7,
            event: .requestChanges,
            body: "Please fix",
            comments: [GithubDraftReviewComment(path: "Sources/A.swift", line: 12, side: "RIGHT", body: "typo")]
        )

        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/pulls/7/reviews")
        let body = try body(of: request)
        #expect(body["event"] as? String == "REQUEST_CHANGES")
        #expect(body["body"] as? String == "Please fix")
        let comments = try #require(body["comments"] as? [[String: Any]])
        #expect(comments.first?["path"] as? String == "Sources/A.swift")
        #expect(comments.first?["line"] as? Int == 12)
        #expect(comments.first?["side"] as? String == "RIGHT")
    }

    @Test("an approval without comments omits the comments key")
    func approveWithoutComments() async throws {
        let transport = StubTransport(data: Data("{}".utf8))

        try await client(transport).submitReview(in: repository, number: 7, event: .approve, body: nil)

        let body = try body(of: try #require(await transport.requests.first))
        #expect(body["event"] as? String == "APPROVE")
        #expect(body["comments"] == nil)
    }

    @Test("addComment posts a single inline comment with the commit id")
    func addComment() async throws {
        let transport = StubTransport(data: Data("{}".utf8))

        try await client(transport).addComment(
            in: repository,
            number: 7,
            commitId: "abc123",
            comment: GithubDraftReviewComment(path: "README.md", line: 3, side: "LEFT", body: "hm")
        )

        let request = try #require(await transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/pulls/7/comments")
        let body = try body(of: request)
        #expect(body["commit_id"] as? String == "abc123")
        #expect(body["side"] as? String == "LEFT")
    }

    @Test("replyToComment posts to the replies endpoint")
    func reply() async throws {
        let transport = StubTransport(data: Data("{}".utf8))

        try await client(transport).replyToComment(in: repository, number: 7, commentId: 99, body: "agreed")

        let request = try #require(await transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/pulls/7/comments/99/replies")
        #expect(try body(of: request)["body"] as? String == "agreed")
    }

    @Test("resolveThread posts the GraphQL mutation")
    func resolve() async throws {
        let transport = StubTransport(data: Data(#"{"data":{}}"#.utf8))

        try await client(transport).resolveThread(id: "RT_node")

        let request = try #require(await transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.github.com/graphql")
        let body = try body(of: request)
        let variables = body["variables"] as? [String: Any]
        #expect(variables?["threadId"] as? String == "RT_node")
        #expect((body["query"] as? String)?.contains("resolveReviewThread") == true)
    }

    @Test("a GraphQL error from resolve surfaces as GithubAPIError")
    func resolveError() async throws {
        let transport = StubTransport(data: Data(#"{"errors":[{"message":"not permitted"}]}"#.utf8))

        await #expect(throws: GithubAPIError(statusCode: 200, message: "not permitted")) {
            try await client(transport).resolveThread(id: "RT_node")
        }
    }
}
