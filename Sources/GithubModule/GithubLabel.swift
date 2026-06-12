/// A label attached to a pull request.
package struct GithubLabel: Sendable, Equatable, Decodable {
    package let name: String
    package let color: String?

    package init(name: String, color: String? = nil) {
        self.name = name
        self.color = color
    }
}
