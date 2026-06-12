/// A non-success response from the GitHub API.
package struct GithubAPIError: Error, Equatable, CustomStringConvertible {
    package let statusCode: Int
    package let message: String

    package init(statusCode: Int, message: String) {
        self.statusCode = statusCode
        self.message = message
    }

    package var description: String { "GitHub API error \(statusCode): \(message)" }
}
