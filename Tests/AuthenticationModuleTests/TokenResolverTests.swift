import Testing
@testable import AuthenticationModule

private actor InMemoryTokenStore: TokenStore {
    private var token: String?
    private let readError: KeychainError?
    private(set) var readCount = 0

    init(token: String? = nil, readError: KeychainError? = nil) {
        self.token = token
        self.readError = readError
    }

    func read() throws -> String? {
        readCount += 1
        if let readError { throw readError }
        return token
    }

    func write(_ token: String) {
        self.token = token
    }

    @discardableResult
    func delete() -> Bool {
        defer { token = nil }
        return token != nil
    }
}

/// Counts invocations so tests can assert lower-priority sources are never consulted.
private actor TokenRecorder {
    private let result: String?
    private(set) var callCount = 0

    init(result: String?) {
        self.result = result
    }

    func provide() -> String? {
        callCount += 1
        return result
    }
}

@Suite("TokenResolver chain")
struct TokenResolverTests {
    @Test("GHPR_TOKEN beats GITHUB_TOKEN, Keychain, and gh")
    func ghprTokenWins() async {
        let store = InMemoryTokenStore(token: "from-keychain")
        let recorder = TokenRecorder(result: "from-gh")
        let resolver = TokenResolver(
            environment: ["GHPR_TOKEN": "from-ghpr", "GITHUB_TOKEN": "from-github"],
            store: store,
            githubCLIToken: { await recorder.provide() }
        )

        let token = await resolver.resolve()

        #expect(token == ResolvedToken(value: "from-ghpr", source: .environment(variable: "GHPR_TOKEN")))
        #expect(await store.readCount == 0)
        #expect(await recorder.callCount == 0)
    }

    @Test("GITHUB_TOKEN is used when GHPR_TOKEN is absent")
    func githubTokenSecond() async {
        let resolver = TokenResolver(
            environment: ["GITHUB_TOKEN": "from-github"],
            store: InMemoryTokenStore(),
            githubCLIToken: { nil }
        )

        let token = await resolver.resolve()

        #expect(token == ResolvedToken(value: "from-github", source: .environment(variable: "GITHUB_TOKEN")))
    }

    @Test("environment values are trimmed, and whitespace-only values are skipped")
    func environmentNormalization() async {
        let resolver = TokenResolver(
            environment: ["GHPR_TOKEN": "  \n", "GITHUB_TOKEN": "  padded-token  "],
            store: InMemoryTokenStore(),
            githubCLIToken: { nil }
        )

        let token = await resolver.resolve()

        #expect(token == ResolvedToken(value: "padded-token", source: .environment(variable: "GITHUB_TOKEN")))
    }

    @Test("Keychain is used when no environment variable is set, without consulting gh")
    func keychainThird() async {
        let recorder = TokenRecorder(result: "from-gh")
        let resolver = TokenResolver(
            environment: [:],
            store: InMemoryTokenStore(token: "from-keychain"),
            githubCLIToken: { await recorder.provide() }
        )

        let token = await resolver.resolve()

        #expect(token == ResolvedToken(value: "from-keychain", source: .keychain))
        #expect(await recorder.callCount == 0)
    }

    @Test("a Keychain read failure falls through to gh")
    func keychainErrorFallsThrough() async {
        let resolver = TokenResolver(
            environment: [:],
            store: InMemoryTokenStore(readError: KeychainError(operation: "read", status: -1)),
            githubCLIToken: { "from-gh" }
        )

        let token = await resolver.resolve()

        #expect(token == ResolvedToken(value: "from-gh", source: .githubCLI))
    }

    @Test("gh is the last resort")
    func githubCLILast() async {
        let resolver = TokenResolver(
            environment: [:],
            store: InMemoryTokenStore(),
            githubCLIToken: { "from-gh" }
        )

        let token = await resolver.resolve()

        #expect(token == ResolvedToken(value: "from-gh", source: .githubCLI))
    }

    @Test("whitespace-only gh output resolves to no token")
    func emptyGhOutput() async {
        let resolver = TokenResolver(
            environment: [:],
            store: InMemoryTokenStore(),
            githubCLIToken: { "  \n" }
        )

        #expect(await resolver.resolve() == nil)
    }

    @Test("no source at all resolves to nil")
    func nothingFound() async {
        let resolver = TokenResolver(
            environment: [:],
            store: InMemoryTokenStore(),
            githubCLIToken: { nil }
        )

        #expect(await resolver.resolve() == nil)
    }
}
