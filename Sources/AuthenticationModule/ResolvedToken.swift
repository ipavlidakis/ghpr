/// A GitHub token together with where it came from.
package struct ResolvedToken: Sendable, Equatable {
    package let value: String
    package let source: TokenSource

    package init(value: String, source: TokenSource) {
        self.value = value
        self.source = source
    }
}

package enum TokenSource: Sendable, Equatable, CustomStringConvertible {
    case environment(variable: String)
    case keychain
    case githubCLI

    package var description: String {
        switch self {
        case .environment(let variable): "\(variable) environment variable"
        case .keychain: "macOS Keychain"
        case .githubCLI: "gh CLI session"
        }
    }
}
