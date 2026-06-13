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

    @Test("addIssueCommentReaction posts to the issue comment reactions endpoint")
    func issueCommentReaction() async throws {
        let transport = StubTransport(data: Data("{}".utf8), statusCode: 201)

        try await client(transport).addIssueCommentReaction(in: repository, commentId: 3001, reaction: .hooray)

        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/issues/comments/3001/reactions")
        #expect(try body(of: request)["content"] as? String == "hooray")
    }

    @Test("toggleReaction adds when this user has not reacted")
    func toggleReactionAdds() async throws {
        let transport = StubTransport(stubs: [
            .init(data: Data(#"{"login":"ipavlidakis","avatar_url":null}"#.utf8)),
            .init(data: Data(#"[]"#.utf8)),
            .init(data: Data("{}".utf8), statusCode: 201),
        ])

        try await client(transport).toggleReaction(in: repository, commentId: 42, reaction: .thumbsUp)

        let requests = await transport.requests
        #expect(requests.map(\.httpMethod) == ["GET", "GET", "POST"])
        #expect(requests[1].url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/pulls/comments/42/reactions?per_page=100")
        #expect(requests[2].url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/pulls/comments/42/reactions")
        #expect(try body(of: requests[2])["content"] as? String == "+1")
    }

    @Test("toggleIssueCommentReaction deletes this user's existing reaction")
    func toggleIssueReactionDeletes() async throws {
        let transport = StubTransport(stubs: [
            .init(data: Data(#"{"login":"ipavlidakis","avatar_url":null}"#.utf8)),
            .init(data: Data(#"[{"id":7001,"content":"heart","user":{"login":"ipavlidakis","avatar_url":null}}]"#.utf8)),
            .init(data: Data("".utf8), statusCode: 204),
        ])

        try await client(transport).toggleIssueCommentReaction(in: repository, commentId: 3001, reaction: .heart)

        let requests = await transport.requests
        #expect(requests.map(\.httpMethod) == ["GET", "GET", "DELETE"])
        #expect(requests[1].url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/issues/comments/3001/reactions?per_page=100")
        #expect(requests[2].url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/reactions/7001")
    }

    @Test("toggleIssueCommentReaction treats missing reaction delete as already removed")
    func toggleIssueReactionIgnoresMissingDelete() async throws {
        let transport = StubTransport(stubs: [
            .init(data: Data(#"{"login":"ipavlidakis","avatar_url":null}"#.utf8)),
            .init(data: Data(#"[{"id":7001,"content":"heart","user":{"login":"ipavlidakis","avatar_url":null}}]"#.utf8)),
            .init(data: Data(#"{"message":"Not Found"}"#.utf8), statusCode: 404),
        ])

        try await client(transport).toggleIssueCommentReaction(in: repository, commentId: 3001, reaction: .heart)

        let requests = await transport.requests
        #expect(requests.map(\.httpMethod) == ["GET", "GET", "DELETE"])
    }

    @Test("toggleReaction treats missing inline reaction delete as already removed")
    func toggleInlineReactionIgnoresMissingDelete() async throws {
        let transport = StubTransport(stubs: [
            .init(data: Data(#"{"login":"ipavlidakis","avatar_url":null}"#.utf8)),
            .init(data: Data(#"[{"id":7002,"content":"eyes","user":{"login":"ipavlidakis","avatar_url":null}}]"#.utf8)),
            .init(data: Data(#"{"message":"Not Found"}"#.utf8), statusCode: 404),
        ])

        try await client(transport).toggleReaction(in: repository, commentId: 42, reaction: .eyes)

        let requests = await transport.requests
        #expect(requests.map(\.httpMethod) == ["GET", "GET", "DELETE"])
        #expect(requests[1].url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/pulls/comments/42/reactions?per_page=100")
        #expect(requests[2].url?.absoluteString == "https://api.github.com/repos/ipavlidakis/ghpr/reactions/7002")
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
