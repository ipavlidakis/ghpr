import Foundation

/// The GraphQL query for review threads, plus mapping of its response
/// envelope onto the clean `GithubReviewThread` model.
enum GithubReviewThreadsQuery {
    struct Request: Encodable {
        struct Variables: Encodable {
            let owner: String
            let name: String
            let number: Int
        }

        let query: String
        let variables: Variables
    }

    static func request(for repository: GithubRepository, number: Int) -> Request {
        Request(
            query: """
                query($owner: String!, $name: String!, $number: Int!) {
                  repository(owner: $owner, name: $name) {
                    pullRequest(number: $number) {
                      reviewThreads(first: 100) {
                        nodes {
                          id
                          isResolved
                          isOutdated
                          path
                          line
                          startLine
                          diffSide
                          comments(first: 100) {
                            nodes {
                              id
                              databaseId
                              author { login }
                              body
                              createdAt
                            }
                          }
                        }
                      }
                    }
                  }
                }
                """,
            variables: Request.Variables(owner: repository.owner, name: repository.name, number: number)
        )
    }

    static func threads(from data: Data) throws -> [GithubReviewThread] {
        let response = try JSONDecoder.github.decode(Response.self, from: data)
        if let error = response.errors?.first {
            throw GithubAPIError(statusCode: 200, message: error.message)
        }
        guard let nodes = response.data?.repository?.pullRequest?.reviewThreads.nodes else {
            throw GithubAPIError(statusCode: 200, message: "GraphQL response missing review threads")
        }
        return nodes.map(\.model)
    }

    // MARK: Response envelope

    private struct Response: Decodable {
        struct GraphQLError: Decodable { let message: String }
        struct DataBody: Decodable { let repository: Repository? }
        struct Repository: Decodable { let pullRequest: PullRequest? }
        struct PullRequest: Decodable { let reviewThreads: ThreadConnection }
        struct ThreadConnection: Decodable { let nodes: [ThreadNode] }
        struct CommentConnection: Decodable { let nodes: [CommentNode] }
        struct Author: Decodable { let login: String }

        struct ThreadNode: Decodable {
            let id: String
            let isResolved: Bool
            let isOutdated: Bool
            let path: String
            let line: Int?
            let startLine: Int?
            let diffSide: String?
            let comments: CommentConnection

            var model: GithubReviewThread {
                GithubReviewThread(
                    id: id,
                    isResolved: isResolved,
                    isOutdated: isOutdated,
                    path: path,
                    line: line,
                    startLine: startLine,
                    diffSide: diffSide,
                    comments: comments.nodes.map(\.model)
                )
            }
        }

        struct CommentNode: Decodable {
            let id: String
            let databaseId: Int?
            let author: Author?
            let body: String
            let createdAt: Date

            var model: GithubReviewComment {
                GithubReviewComment(
                    id: id,
                    databaseId: databaseId,
                    authorLogin: author?.login,
                    body: body,
                    createdAt: createdAt
                )
            }
        }

        let data: DataBody?
        let errors: [GraphQLError]?
    }
}
