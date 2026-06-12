import Foundation

extension GithubRepository {
    /// Parses `owner/name` out of a git remote URL.
    ///
    /// Supports the SSH (`git@host:owner/repo.git`), SSH-URL
    /// (`ssh://git@host/owner/repo.git`), and HTTPS (`https://host/owner/repo`)
    /// forms. The host is not validated, which keeps GitHub Enterprise working.
    package init?(remoteURL: String) {
        var trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") { trimmed.removeLast() }
        if trimmed.hasSuffix(".git") { trimmed.removeLast(4) }

        let path: Substring
        if let schemeRange = trimmed.range(of: "://") {
            // ssh://git@host/owner/repo or https://host/owner/repo
            guard let hostEnd = trimmed[schemeRange.upperBound...].firstIndex(of: "/") else { return nil }
            path = trimmed[trimmed.index(after: hostEnd)...]
        } else if let colon = trimmed.firstIndex(of: ":"), trimmed.contains("@") {
            // git@host:owner/repo
            path = trimmed[trimmed.index(after: colon)...]
        } else {
            return nil
        }

        let components = path.split(separator: "/")
        guard components.count == 2, !components[0].isEmpty, !components[1].isEmpty else { return nil }
        self.init(owner: String(components[0]), name: String(components[1]))
    }
}
