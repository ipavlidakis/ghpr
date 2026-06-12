/// Where a resolved token came from, in the order the chain probes them.
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
