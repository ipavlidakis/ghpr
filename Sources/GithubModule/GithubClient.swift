import Foundation

/// Async client for the GitHub REST and GraphQL APIs (read path).
package actor GithubClient {
    private let token: String
    private let transport: any HTTPTransport
    private let apiBaseURL: URL

    package init(
        token: String,
        transport: any HTTPTransport = URLSessionTransport(),
        apiBaseURL: URL = URL(string: "https://api.github.com")!
    ) {
        self.token = token
        self.transport = transport
        self.apiBaseURL = apiBaseURL
    }

    /// The user the token belongs to (drives dashboard filters).
    package func authenticatedUser() async throws -> GithubUser {
        let (data, _) = try await send(request(path: "user"))
        return try JSONDecoder.github.decode(GithubUser.self, from: data)
    }

    // MARK: Pull requests

    package func pullRequest(in repository: GithubRepository, number: Int) async throws -> GithubPullRequest {
        let (data, _) = try await send(request(path: "repos/\(repository.fullName)/pulls/\(number)"))
        return try JSONDecoder.github.decode(GithubPullRequest.self, from: data)
    }

    package func openPullRequests(in repository: GithubRepository) async throws -> [GithubPullRequest] {
        try await pages(path: "repos/\(repository.fullName)/pulls", query: [URLQueryItem(name: "state", value: "open")])
    }

    /// The open PR whose head is `branch` of the repository's owner, or `nil` when there is none.
    package func openPullRequest(in repository: GithubRepository, branch: String) async throws -> GithubPullRequest? {
        let query = [
            URLQueryItem(name: "state", value: "open"),
            URLQueryItem(name: "head", value: "\(repository.owner):\(branch)")
        ]
        let (data, _) = try await send(request(path: "repos/\(repository.fullName)/pulls", query: query))
        return try JSONDecoder.github.decode([GithubPullRequest].self, from: data).first
    }

    /// The unified diff of a pull request.
    package func diff(in repository: GithubRepository, number: Int) async throws -> String {
        let (data, _) = try await send(request(path: "repos/\(repository.fullName)/pulls/\(number)", accept: "application/vnd.github.diff"))
        return String(decoding: data, as: UTF8.self)
    }

    package func commits(in repository: GithubRepository, number: Int) async throws -> [GithubCommit] {
        try await pages(path: "repos/\(repository.fullName)/pulls/\(number)/commits", query: [])
    }

    /// The raw contents of a file at a specific ref.
    package func fileContent(in repository: GithubRepository, path: String, ref: String) async throws -> String {
        String(decoding: try await fileData(in: repository, path: path, ref: ref), as: UTF8.self)
    }

    /// The raw bytes of a file at a specific ref (binary files).
    package func fileData(in repository: GithubRepository, path: String, ref: String) async throws -> Data {
        let request = request(
            path: "repos/\(repository.fullName)/contents/\(path)",
            query: [URLQueryItem(name: "ref", value: ref)],
            accept: "application/vnd.github.raw+json"
        )
        let (data, _) = try await send(request)
        return data
    }

    // MARK: Checks

    package func checkRuns(in repository: GithubRepository, ref: String) async throws -> [GithubCheckRun] {
        var url: URL? = url(path: "repos/\(repository.fullName)/commits/\(ref)/check-runs", query: [perPage])
        var runs: [GithubCheckRun] = []
        while let pageURL = url {
            let (data, response) = try await send(request(url: pageURL))
            runs += try JSONDecoder.github.decode(GithubCheckRunsResponse.self, from: data).checkRuns
            url = LinkHeader.nextURL(from: response.value(forHTTPHeaderField: "Link"))
        }
        return runs
    }

    // MARK: Conversation timeline

    /// The PR conversation in display order: comments, reviews, commits,
    /// and the label/assignment/review-request events ghpr renders.
    package func timeline(in repository: GithubRepository, number: Int) async throws -> [GithubTimelineItem] {
        let items: [GithubTimelineItem] = try await pages(
            path: "repos/\(repository.fullName)/issues/\(number)/timeline",
            query: []
        )
        return items.filter { $0 != .unknown }
    }

    // MARK: Review threads

    package func reviewThreads(in repository: GithubRepository, number: Int) async throws -> [GithubReviewThread] {
        let payload = try JSONEncoder().encode(GithubReviewThreadsQuery.request(for: repository, number: number))
        var graphQLRequest = request(url: apiBaseURL.appending(path: "graphql"))
        graphQLRequest.httpMethod = "POST"
        graphQLRequest.httpBody = payload

        let (data, _) = try await send(graphQLRequest)
        return try GithubReviewThreadsQuery.threads(from: data)
    }

    // MARK: Write path

    /// Submits a review: the verdict, an optional summary, and the pending
    /// inline comments as one batch.
    package func submitReview(
        in repository: GithubRepository,
        number: Int,
        event: GithubReviewEvent,
        body: String?,
        comments: [GithubDraftReviewComment] = []
    ) async throws {
        struct Payload: Encodable {
            let event: String
            let body: String?
            let comments: [GithubDraftReviewComment]?
        }
        try await post(
            path: "repos/\(repository.fullName)/pulls/\(number)/reviews",
            payload: Payload(event: event.rawValue, body: body, comments: comments.isEmpty ? nil : comments)
        )
    }

    /// Adds one immediate (non-batched) inline comment.
    package func addComment(
        in repository: GithubRepository,
        number: Int,
        commitId: String,
        comment: GithubDraftReviewComment
    ) async throws {
        struct Payload: Encodable {
            let body: String
            let commitId: String
            let path: String
            let line: Int
            let side: String
        }
        try await post(
            path: "repos/\(repository.fullName)/pulls/\(number)/comments",
            payload: Payload(body: comment.body, commitId: commitId, path: comment.path, line: comment.line, side: comment.side)
        )
    }

    /// Replies to an existing inline comment (and thereby its thread).
    package func replyToComment(
        in repository: GithubRepository,
        number: Int,
        commentId: Int,
        body: String
    ) async throws {
        struct Payload: Encodable {
            let body: String
        }
        try await post(
            path: "repos/\(repository.fullName)/pulls/\(number)/comments/\(commentId)/replies",
            payload: Payload(body: body)
        )
    }

    /// Adds an emoji reaction to an inline comment.
    package func addReaction(
        in repository: GithubRepository,
        commentId: Int,
        reaction: GithubReactionContent
    ) async throws {
        struct Payload: Encodable {
            let content: String
        }
        try await post(
            path: "repos/\(repository.fullName)/pulls/comments/\(commentId)/reactions",
            payload: Payload(content: reaction.restValue)
        )
    }

    /// Adds an emoji reaction to a conversation (issue) comment.
    package func addIssueCommentReaction(
        in repository: GithubRepository,
        commentId: Int,
        reaction: GithubReactionContent
    ) async throws {
        struct Payload: Encodable {
            let content: String
        }
        try await post(
            path: "repos/\(repository.fullName)/issues/comments/\(commentId)/reactions",
            payload: Payload(content: reaction.restValue)
        )
    }

    /// Marks a review thread as resolved.
    package func resolveThread(id: String) async throws {
        // GraphQL variables are camelCase — no snake_case encoding here.
        let payload = try JSONEncoder().encode(GithubResolveThreadMutation.request(threadId: id))
        var request = request(url: apiBaseURL.appending(path: "graphql"))
        request.httpMethod = "POST"
        request.httpBody = payload

        let (data, _) = try await send(request)
        try GithubResolveThreadMutation.validate(data)
    }

    /// Reopens a resolved review thread.
    package func unresolveThread(id: String) async throws {
        let payload = try JSONEncoder().encode(GithubUnresolveThreadMutation.request(threadId: id))
        var request = request(url: apiBaseURL.appending(path: "graphql"))
        request.httpMethod = "POST"
        request.httpBody = payload

        let (data, _) = try await send(request)
        try GithubUnresolveThreadMutation.validate(data)
    }

    // MARK: Request building

    private var perPage: URLQueryItem { URLQueryItem(name: "per_page", value: "100") }

    private func url(path: String, query: [URLQueryItem] = []) -> URL {
        var url = apiBaseURL.appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query)
        }
        return url
    }

    private func request(path: String, query: [URLQueryItem] = [], accept: String = "application/vnd.github+json") -> URLRequest {
        request(url: url(path: path, query: query), accept: accept)
    }

    private func request(url: URL, accept: String = "application/vnd.github+json") -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("ghpr", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func pages<Element: Decodable>(path: String, query: [URLQueryItem]) async throws -> [Element] {
        var url: URL? = url(path: path, query: query + [perPage])
        var elements: [Element] = []
        while let pageURL = url {
            let (data, response) = try await send(request(url: pageURL))
            elements += try JSONDecoder.github.decode([Element].self, from: data)
            url = LinkHeader.nextURL(from: response.value(forHTTPHeaderField: "Link"))
        }
        return elements
    }

    private func post(path: String, payload: some Encodable) async throws {
        var request = request(path: path)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder.github.encode(payload)
        _ = try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw GithubAPIError(statusCode: response.statusCode, message: Self.errorMessage(from: data))
        }
        return (data, response)
    }

    private static func errorMessage(from data: Data) -> String {
        struct ErrorBody: Decodable { let message: String }
        let decoded = try? JSONDecoder().decode(ErrorBody.self, from: data)
        return decoded?.message ?? String(decoding: data, as: UTF8.self)
    }
}
