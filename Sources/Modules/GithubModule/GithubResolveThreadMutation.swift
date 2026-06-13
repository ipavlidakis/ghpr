import Foundation

/// The GraphQL mutation that resolves a review thread (REST has no
/// equivalent), plus its response validation.
enum GithubResolveThreadMutation {
    struct Request: Encodable {
        struct Variables: Encodable {
            let threadId: String
        }

        let query: String
        let variables: Variables
    }

    static func request(threadId: String) -> Request {
        Request(
            query: """
                mutation($threadId: ID!) {
                  resolveReviewThread(input: { threadId: $threadId }) {
                    thread { id isResolved }
                  }
                }
                """,
            variables: Request.Variables(threadId: threadId)
        )
    }

    static func validate(_ data: Data) throws {
        struct Response: Decodable {
            struct GraphQLError: Decodable { let message: String }
            let errors: [GraphQLError]?
        }
        if let error = try JSONDecoder.github.decode(Response.self, from: data).errors?.first {
            throw GithubAPIError(statusCode: 200, message: error.message)
        }
    }
}
