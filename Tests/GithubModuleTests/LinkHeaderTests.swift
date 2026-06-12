import Foundation
import Testing
import GithubModule

/// Covers GitHub's pagination `Link` header parsing.
@Suite("LinkHeader")
struct LinkHeaderTests {
    @Test("extracts the next page URL")
    func next() {
        let header = #"<https://api.github.com/repos/a/b/pulls?page=2>; rel="next", <https://api.github.com/repos/a/b/pulls?page=9>; rel="last""#
        #expect(LinkHeader.nextURL(from: header)?.absoluteString == "https://api.github.com/repos/a/b/pulls?page=2")
    }

    @Test("returns nil on the last page")
    func lastPage() {
        let header = #"<https://api.github.com/repos/a/b/pulls?page=1>; rel="prev", <https://api.github.com/repos/a/b/pulls?page=1>; rel="first""#
        #expect(LinkHeader.nextURL(from: header) == nil)
    }

    @Test("returns nil for a missing or malformed header", arguments: [nil, "", "nonsense"] as [String?])
    func missing(header: String?) {
        #expect(LinkHeader.nextURL(from: header) == nil)
    }
}
