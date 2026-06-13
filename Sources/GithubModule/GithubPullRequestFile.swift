import Foundation

/// One file from the Pull Request Files REST endpoint.
package struct GithubPullRequestFile: Sendable, Equatable, Decodable {
    package let filename: String
    package let previousFilename: String?
    package let status: String
    package let patch: String?

    package init(filename: String, previousFilename: String? = nil, status: String, patch: String? = nil) {
        self.filename = filename
        self.previousFilename = previousFilename
        self.status = status
        self.patch = patch
    }

    package var unifiedDiffSection: String {
        let oldPath = previousFilename ?? filename
        let newPath = filename
        var lines = ["diff --git a/\(oldPath) b/\(newPath)"]

        switch status {
        case "added":
            lines.append("new file mode 100644")
            lines.append("--- /dev/null")
            lines.append("+++ b/\(newPath)")
        case "removed":
            lines.append("deleted file mode 100644")
            lines.append("--- a/\(oldPath)")
            lines.append("+++ /dev/null")
        case "renamed":
            lines.append("rename from \(oldPath)")
            lines.append("rename to \(newPath)")
            lines.append("--- a/\(oldPath)")
            lines.append("+++ b/\(newPath)")
        default:
            lines.append("--- a/\(oldPath)")
            lines.append("+++ b/\(newPath)")
        }

        if let patch, !patch.isEmpty {
            lines.append(patch)
        } else {
            lines.append("Binary files a/\(oldPath) and b/\(newPath) differ")
        }

        return lines.joined(separator: "\n")
    }
}
