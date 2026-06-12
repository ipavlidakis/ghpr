import Foundation

/// Resolves the GitHub token from the highest-priority available source:
/// `GHPR_TOKEN` env var → `GITHUB_TOKEN` env var → macOS Keychain → `gh` CLI borrow.
package actor TokenResolver {
    package static let environmentVariables = ["GHPR_TOKEN", "GITHUB_TOKEN"]

    private let environment: [String: String]
    private let store: any TokenStore
    private let githubCLIToken: @Sendable () async -> String?

    package init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        store: any TokenStore = KeychainTokenStore(),
        githubCLIToken: @escaping @Sendable () async -> String? = { await GithubCLITokenProvider.token() }
    ) {
        self.environment = environment
        self.store = store
        self.githubCLIToken = githubCLIToken
    }

    package func resolve() async -> ResolvedToken? {
        for variable in Self.environmentVariables {
            if let token = normalized(environment[variable]) {
                return ResolvedToken(value: token, source: .environment(variable: variable))
            }
        }

        // Resolution is best-effort: a Keychain read failure falls through to the
        // next source. Explicit `ghpr auth` commands surface store errors instead.
        if let token = normalized((try? await store.read()) ?? nil) {
            return ResolvedToken(value: token, source: .keychain)
        }

        if let token = normalized(await githubCLIToken()) {
            return ResolvedToken(value: token, source: .githubCLI)
        }

        return nil
    }

    private func normalized(_ raw: String?) -> String? {
        guard let token = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            return nil
        }
        return token
    }
}
