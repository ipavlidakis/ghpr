import Foundation

/// Why the current directory cannot be mapped to an open pull request.
package enum LocalRepositoryError: Error, Equatable, CustomStringConvertible {
    case notAGitRepository(directory: String)
    case noOriginRemote
    case detachedHead
    case unrecognizedOriginURL(String)

    package var description: String {
        switch self {
        case .notAGitRepository(let directory):
            "\(directory) is not inside a git repository."
        case .noOriginRemote:
            "The repository has no `origin` remote."
        case .detachedHead:
            "HEAD is detached — check out a branch to look up its pull request."
        case .unrecognizedOriginURL(let url):
            "Could not parse a GitHub repository out of the origin URL: \(url)"
        }
    }
}
