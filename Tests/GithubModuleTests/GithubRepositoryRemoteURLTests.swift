import Testing
import GithubModule

@Suite("GithubRepository remote URL parsing")
struct GithubRepositoryRemoteURLTests {
    private let expected = GithubRepository(owner: "ipavlidakis", name: "ghpr")

    @Test(
        "recognized forms",
        arguments: [
            "git@github.com:ipavlidakis/ghpr.git",
            "git@github.com:ipavlidakis/ghpr",
            "ssh://git@github.com/ipavlidakis/ghpr.git",
            "https://github.com/ipavlidakis/ghpr.git",
            "https://github.com/ipavlidakis/ghpr",
            "https://github.com/ipavlidakis/ghpr/",
            "  https://github.com/ipavlidakis/ghpr.git\n"
        ]
    )
    func parses(remoteURL: String) {
        #expect(GithubRepository(remoteURL: remoteURL) == expected)
    }

    @Test(
        "rejected forms",
        arguments: [
            "",
            "not a url",
            "https://github.com/ipavlidakis",
            "https://github.com/a/b/c",
            "git@github.com:single-component.git"
        ]
    )
    func rejects(remoteURL: String) {
        #expect(GithubRepository(remoteURL: remoteURL) == nil)
    }

    @Test("Enterprise hosts are accepted")
    func enterpriseHost() {
        #expect(
            GithubRepository(remoteURL: "git@github.acme.com:team/tool.git")
                == GithubRepository(owner: "team", name: "tool")
        )
    }
}
