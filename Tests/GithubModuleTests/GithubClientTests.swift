import Foundation
import Testing
import GithubModule

/// Drives the client against scripted transports replaying captured fixtures.
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
        // Reloads after writes must never see GitHub's 60-second cache.
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
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

    @Test("diff falls back to pull request files when GitHub refuses large diffs")
    func diffFilesFallback() async throws {
        let files = Data(#"""
        [
          {
            "filename": "Sources/New.swift",
            "status": "added",
            "patch": "@@ -0,0 +1,1 @@\n+let value = 1"
          },
          {
            "filename": "Sources/Renamed.swift",
            "previous_filename": "Sources/Old.swift",
            "status": "renamed",
            "patch": "@@ -1,1 +1,1 @@\n-old\n+new"
          }
        ]
        """#.utf8)
        let transport = StubTransport(stubs: [
            .init(
                data: Data(#"{"message":"Sorry, the diff exceeded the maximum number of files (300)."}"#.utf8),
                statusCode: 406
            ),
            .init(data: files),
        ])

        let diff = try await client(transport).diff(in: repository, number: 908)

        #expect(diff.contains("diff --git a/Sources/New.swift b/Sources/New.swift"))
        #expect(diff.contains("new file mode 100644"))
        #expect(diff.contains("rename from Sources/Old.swift"))
        #expect(diff.contains("+let value = 1"))
        let requests = await transport.requests
        #expect(requests.map(\.httpMethod) == ["GET", "GET"])
        #expect(requests[0].value(forHTTPHeaderField: "Accept") == "application/vnd.github.diff")
        #expect(requests[1].url?.absoluteString == "https://api.github.com/repos/apple/swift-argument-parser/pulls/908/files?per_page=100")
    }

    @Test("commits decode from the captured fixture")
    func commits() async throws {
        let transport = StubTransport(data: try Fixture.data("commits.json"))

        let commits = try await client(transport).commits(in: repository, number: 908)

        #expect(commits.count == 5)
        let first = try #require(commits.first)
        #expect(first.shortSha == "fc86f29")
        #expect(first.summary == "Revert source break in 1.8.0 `parse` methods")
        #expect(first.authorName == "natecook1000")
        #expect(first.authoredAt != nil)
        let url = try #require(await transport.requests.first?.url?.absoluteString)
        #expect(url.contains("pulls/908/commits"))
    }

    @Test("authenticatedUser decodes the /user payload")
    func authenticatedUser() async throws {
        let transport = StubTransport(data: Data(#"{"login":"ipavlidakis","avatar_url":"https://a.example/u.png"}"#.utf8))

        let user = try await client(transport).authenticatedUser()

        #expect(user.login == "ipavlidakis")
        #expect(await transport.requests.first?.url?.absoluteString == "https://api.github.com/user")
    }

    @Test("fileContent requests raw contents at the ref")
    func fileContent() async throws {
        let transport = StubTransport(data: Data("let a = 1\n".utf8))

        let content = try await client(transport).fileContent(in: repository, path: "Sources/A.swift", ref: "abc123")

        #expect(content == "let a = 1\n")
        let request = try #require(await transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.github.com/repos/apple/swift-argument-parser/contents/Sources/A.swift?ref=abc123")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github.raw+json")
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

    @Test("timeline decodes supported entries and drops unsupported events")
    func timeline() async throws {
        let transport = StubTransport(data: try Fixture.data("timeline.json"))

        let timeline = try await client(transport).timeline(in: repository, number: 908)

        // The "subscribed" entry is unsupported and filtered out.
        #expect(timeline.count == 8)

        guard case .commit(let commit) = timeline[0] else {
            Issue.record("expected a commit first, got \(timeline[0])")
            return
        }
        #expect(commit.sha.hasPrefix("45135a5"))
        #expect(commit.message.hasPrefix("[Enhancement]Integrate"))
        #expect(commit.authorName == "Ilias Pavlidakis")

        guard case .event(let assigned) = timeline[1] else {
            Issue.record("expected an assignment event, got \(timeline[1])")
            return
        }
        #expect(assigned.kind == .assigned)
        #expect(assigned.actorLogin == "ipavlidakis")
        #expect(assigned.assigneeLogin == "ipavlidakis")

        guard case .event(let requested) = timeline[2] else {
            Issue.record("expected a review request event, got \(timeline[2])")
            return
        }
        #expect(requested.kind == .reviewRequested)
        #expect(requested.requestedReviewerName == "ios-developers")

        guard case .event(let labeled) = timeline[3] else {
            Issue.record("expected a label event, got \(timeline[3])")
            return
        }
        #expect(labeled.kind == .labeled)
        #expect(labeled.label == GithubLabel(name: "enhancement", color: "a2eeef"))

        guard case .event(let milestoned) = timeline[4] else {
            Issue.record("expected a milestone event, got \(timeline[4])")
            return
        }
        #expect(milestoned.kind == .milestoned)
        #expect(milestoned.milestoneTitle == "1.40.0")

        guard case .comment(let comment) = timeline[5] else {
            Issue.record("expected a comment, got \(timeline[5])")
            return
        }
        #expect(comment.databaseId == 3001)
        #expect(comment.authorLogin == "coderabbitai[bot]")
        #expect(comment.isEdited == true)
        #expect(comment.reactions == [
            GithubReaction(content: .thumbsUp, count: 2),
            GithubReaction(content: .hooray, count: 1),
        ])

        guard case .review(let review) = timeline[6] else {
            Issue.record("expected a review, got \(timeline[6])")
            return
        }
        #expect(review.state == "approved")
        #expect(review.authorLogin == "martinmitrevski")
        #expect(review.body == "LGTM!")
        #expect(review.databaseId == 2877001122)

        guard case .event(let renamed) = timeline[7] else {
            Issue.record("expected a rename event, got \(timeline[7])")
            return
        }
        #expect(renamed.kind == .renamed)
        #expect(renamed.renamedFrom == "WIP title")
        #expect(renamed.renamedTo == "Final title")

        let url = try #require(await transport.requests.first?.url?.absoluteString)
        #expect(url.contains("issues/908/timeline"))
    }

    @Test("timeline sorts supported entries chronologically")
    func timelineSortsChronologically() async throws {
        let body = Data(#"""
        [
          {
            "event": "commented",
            "id": 2,
            "body": "newer",
            "created_at": "2026-06-13T10:00:00Z",
            "updated_at": "2026-06-13T10:00:00Z",
            "user": {"login": "bot", "avatar_url": null},
            "author_association": "NONE",
            "reactions": {}
          },
          {
            "event": "commented",
            "id": 1,
            "body": "older",
            "created_at": "2026-06-13T09:00:00Z",
            "updated_at": "2026-06-13T09:00:00Z",
            "user": {"login": "bot", "avatar_url": null},
            "author_association": "NONE",
            "reactions": {}
          }
        ]
        """#.utf8)
        let transport = StubTransport(data: body)

        let timeline = try await client(transport).timeline(in: repository, number: 908)

        guard case .comment(let first) = timeline.first else {
            Issue.record("expected a comment first, got \(String(describing: timeline.first))")
            return
        }
        #expect(first.databaseId == 1)
    }

    @Test("pull request assignees decode when present")
    func assignees() async throws {
        let transport = StubTransport(data: try Fixture.data("pull-request.json"))

        let pullRequest = try await client(transport).pullRequest(in: repository, number: 908)

        #expect(pullRequest.assignees != nil)
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
        #expect(first.resolvedByLogin == "natecook1000")
        #expect(first.comments.first?.authorLogin == "rgoldberg")
        #expect(first.comments.first?.diffHunk?.hasPrefix("@@ -53,6 +53,10 @@") == true)
        #expect(first.reviewDatabaseId == 2877001122)
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
