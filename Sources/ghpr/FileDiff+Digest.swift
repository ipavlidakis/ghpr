import CryptoKit
import DiffUIModule
import Foundation

/// Content identity for viewed-state invalidation.
extension FileDiff {
    /// Stable digest of this file's patch. If the diff changes between
    /// sessions, the digest changes and any stored "viewed" mark expires.
    var contentDigest: String {
        var hasher = SHA256()
        hasher.update(data: Data(path.utf8))
        for hunk in hunks {
            hasher.update(data: Data(hunk.header.utf8))
            for line in hunk.lines {
                hasher.update(data: Data(line.text.utf8))
                hasher.update(data: Data([lineMarker(for: line.kind)]))
            }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func lineMarker(for kind: DiffLineKind) -> UInt8 {
        switch kind {
        case .context: 0
        case .addition: 1
        case .deletion: 2
        }
    }
}
