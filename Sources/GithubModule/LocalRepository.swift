import Foundation

/// Read-only git queries against a local working directory.
///
/// ghpr never writes to the repository; these two questions — "which GitHub
/// repo is this?" and "which branch is checked out?" — are all it ever asks.
package actor LocalRepository {
    private let directory: String

    package init(directory: String = FileManager.default.currentDirectoryPath) {
        self.directory = directory
    }

    /// The GitHub repository behind the `origin` remote.
    package func repository() async throws -> GithubRepository {
        let result = await git("remote", "get-url", "origin")
        guard result.succeeded else {
            try await ensureGitRepository()
            throw LocalRepositoryError.noOriginRemote
        }
        guard let repository = GithubRepository(remoteURL: result.output) else {
            throw LocalRepositoryError.unrecognizedOriginURL(result.output)
        }
        return repository
    }

    /// The currently checked-out branch name.
    package func currentBranch() async throws -> String {
        let result = await git("symbolic-ref", "--short", "HEAD")
        guard result.succeeded else {
            try await ensureGitRepository()
            throw LocalRepositoryError.detachedHead
        }
        return result.output
    }

    /// Re-checks repo-ness so callers get the most specific error.
    private func ensureGitRepository() async throws {
        let result = await git("rev-parse", "--is-inside-work-tree")
        guard result.succeeded, result.output == "true" else {
            throw LocalRepositoryError.notAGitRepository(directory: directory)
        }
    }

    private func git(_ arguments: String...) async -> Subprocess.Result {
        await Subprocess.run(["git", "-C", directory] + arguments)
    }
}
