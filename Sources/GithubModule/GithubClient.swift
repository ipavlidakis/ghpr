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

    // MARK: Review threads

    package func reviewThreads(in repository: GithubRepository, number: Int) async throws -> [GithubReviewThread] {
        let payload = try JSONEncoder().encode(GithubReviewThreadsQuery.request(for: repository, number: number))
        var graphQLRequest = request(url: apiBaseURL.appending(path: "graphql"))
        graphQLRequest.httpMethod = "POST"
        graphQLRequest.httpBody = payload

        let (data, _) = try await send(graphQLRequest)
        return try GithubReviewThreadsQuery.threads(from: data)
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
