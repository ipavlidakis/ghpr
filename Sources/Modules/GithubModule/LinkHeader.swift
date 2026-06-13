import Foundation

/// Parses the RFC 5988 `Link` response header GitHub uses for pagination.
package enum LinkHeader {
    /// The URL marked `rel="next"`, or `nil` on the last page.
    package static func nextURL(from header: String?) -> URL? {
        guard let header else { return nil }

        for entry in header.split(separator: ",") {
            let parts = entry.split(separator: ";", maxSplits: 1)
            guard parts.count == 2, parts[1].contains("rel=\"next\"") else { continue }
            let target = parts[0].trimmingCharacters(in: .whitespaces)
            guard target.hasPrefix("<"), target.hasSuffix(">") else { continue }
            return URL(string: String(target.dropFirst().dropLast()))
        }
        return nil
    }
}
