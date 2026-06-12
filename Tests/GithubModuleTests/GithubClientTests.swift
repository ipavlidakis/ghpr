import Foundation
import Testing
import GithubModule

@Suite("GithubClient")
struct GithubClientTests {
    private let repository = GithubRepository(owner: "apple", name: "swift-argument-parser")

    private func client(_ transport: StubTransport) -> GithubClient {
        GithubClient(token: "test-token", transport: transport)
    }

    @Test("pullRequest hits the detail endpoint with auth headers and decodes the fixture")
    func pullRequestDetail() async throws {
        let transport = StubTransport(data: try Fixture.data("pull-request.json"))

        let pullRequest = try await client(transport).pullRequest(in: repository, number: 908)

        #expect(pullRequest.number == 908)
        #expect(pullRequest.title == "Revert source break in 1.8.0 `parse` methods")
        #expect(pullRequest.user?.login == "natecook1000")
        #expect(pullRequest.state == "closed")
        #expect(pullRequest.draft == false)
        #expect(pullRequest.head.ref == "fix-asyncparse-break")
        #expect(pullRequest.head.sha == "4157f4816b1736210581a02886d9f85d5fe6c589")
        #expect(pullRequest.base.ref == "main")
        #expect(pullRequest.additions == 34)
        #expect(pullRequest.deletions == 12)
        #expect(pullRequest.changedFiles == 5)

        let request = try #require(await transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.github.com/repos/apple/swift-argument-parser/pulls/908")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
        #expect(request.value(forHTTPHeaderField: "X-GitHub-Api-Version") == "2022-11-28")
    }

    @Test("openPullRequests follows the Link header across pages")
    func openPullRequestsPagination() async throws {
        let page = try Fixture.data("pull-request-list.json")
        let nextURL = "https://api.github.com/repos/apple/swift-argument-parser/pulls?state=open&per_page=100&page=2"
        let transport = StubTransport(stubs: [
            .init(data: page, headers: ["Link": "<\(nextURL)>; rel=\"next\""]),
            .init(data: page)
        ])

        let pullRequests = try await client(transport).openPullRequests(in: repository)

        #expect(pullRequests.count == 10)
        // List payloads omit the detail-only counters.
        #expect(pullRequests[0].additions == nil)

        let urls = await transport.requests.map { $0.url?.absoluteString }
        #expect(urls.count == 2)
        #expect(urls[0]?.contains("state=open") == true)
        #expect(urls[0]?.contains("per_page=100") == true)
        #expect(urls[1] == nextURL)
    }

    @Test("openPullRequest filters by owner-qualified head branch")
    func openPullRequestForBranch() async throws {
        let transport = StubTransport(data: try Fixture.data("pull-request-list.json"))

        let pullRequest = try await client(transport).openPullRequest(in: repository, branch: "fix-asyncparse-break")

        #expect(pullRequest?.number == 915)
        let url = try #require(await transport.requests.first?.url?.absoluteString)
        #expect(url.contains("head=apple:fix-asyncparse-break"))
        #expect(url.contains("state=open"))
    }

    @Test("openPullRequest returns nil when no PR exists for the branch")
    func openPullRequestMiss() async throws {
        let transport = StubTransport(data: Data("[]".utf8))

        let pullRequest = try await client(transport).openPullRequest(in: repository, branch: "orphan")

        #expect(pullRequest == nil)
    }

    @Test("diff requests the diff media type and returns the raw patch")
    func diffMediaType() async throws {
        let transport = StubTransport(data: try Fixture.data("pull-request.diff"))

        let diff = try await client(transport).diff(in: repository, number: 908)

        #expect(diff.hasPrefix("diff --git"))
        let request = try #require(await transport.requests.first)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github.diff")
    }

    @Test("checkRuns unwraps the envelope")
    func checkRuns() async throws {
        let transport = StubTransport(data: try Fixture.data("check-runs.json"))

        let runs = try await client(transport).checkRuns(in: repository, ref: "4157f4816b1736210581a02886d9f85d5fe6c589")

        #expect(runs.count == 34)
        #expect(runs[0].name == "Required")
        #expect(runs[0].status == "completed")
        #expect(runs[0].conclusion == "success")
        let url = try #require(await transport.requests.first?.url?.absoluteString)
        #expect(url.contains("commits/4157f4816b1736210581a02886d9f85d5fe6c589/check-runs"))
    }

    @Test("reviewThreads posts the GraphQL query and maps the response")
    func reviewThreads() async throws {
        let transport = StubTransport(data: try Fixture.data("review-threads.json"))

        let threads = try await client(transport).reviewThreads(in: repository, number: 908)

        #expect(threads.count == 4)
        let first = try #require(threads.first)
        #expect(first.path == "Sources/ArgumentParser/Parsing/CommandParser.swift")
        #expect(first.isResolved == true)
        #expect(first.isOutdated == true)
        #expect(first.line == nil)
        #expect(first.comments.first?.authorLogin == "rgoldberg")
        #expect(threads.count(where: \.isResolved) == 1)

        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.github.com/graphql")
        let body = try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as? [String: Any]
        let variables = body?["variables"] as? [String: Any]
        #expect(variables?["owner"] as? String == "apple")
        #expect(variables?["name"] as? String == "swift-argument-parser")
        #expect(variables?["number"] as? Int == 908)
    }

    @Test("GraphQL errors surface as GithubAPIError")
    func graphQLError() async throws {
        let transport = StubTransport(data: Data(#"{"errors":[{"message":"boom"}]}"#.utf8))

        await #expect(throws: GithubAPIError(statusCode: 200, message: "boom")) {
            try await client(transport).reviewThreads(in: repository, number: 908)
        }
    }

    @Test("non-2xx responses throw a GithubAPIError with the API message")
    func errorMapping() async throws {
        let transport = StubTransport(data: Data(#"{"message":"Not Found"}"#.utf8), statusCode: 404)

        await #expect(throws: GithubAPIError(statusCode: 404, message: "Not Found")) {
            try await client(transport).pullRequest(in: repository, number: 1)
        }
    }
}
