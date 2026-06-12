import Foundation
import Testing
@testable import GithubModule

/// Exercises real read-only git against throwaway repositories in a temp directory.
@Suite("LocalRepository")
final class LocalRepositoryTests {
    private let directory: String

    init() throws {
        directory = NSTemporaryDirectory() + "ghpr-tests-" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(atPath: directory)
    }

    private func git(_ arguments: String...) async {
        _ = await Subprocess.run(["git", "-C", directory] + arguments)
    }

    @Test("resolves origin remote and current branch")
    func happyPath() async throws {
        await git("init", "--initial-branch", "feature/my-branch")
        await git("remote", "add", "origin", "git@github.com:ipavlidakis/ghpr.git")
        let repository = LocalRepository(directory: directory)

        #expect(try await repository.repository() == GithubRepository(owner: "ipavlidakis", name: "ghpr"))
        #expect(try await repository.currentBranch() == "feature/my-branch")
    }

    @Test("a plain directory is not a git repository")
    func notARepository() async throws {
        let repository = LocalRepository(directory: directory)

        await #expect(throws: LocalRepositoryError.notAGitRepository(directory: directory)) {
            try await repository.repository()
        }
    }

    @Test("a repository without origin reports the missing remote")
    func noOrigin() async throws {
        await git("init")
        let repository = LocalRepository(directory: directory)

        await #expect(throws: LocalRepositoryError.noOriginRemote) {
            try await repository.repository()
        }
    }

    @Test("a non-GitHub origin URL is rejected with the URL in the error")
    func unrecognizedOrigin() async throws {
        await git("init")
        await git("remote", "add", "origin", "/local/bare/repo.git")
        let repository = LocalRepository(directory: directory)

        await #expect(throws: LocalRepositoryError.unrecognizedOriginURL("/local/bare/repo.git")) {
            try await repository.repository()
        }
    }

    @Test("detached HEAD is reported as such")
    func detachedHead() async throws {
        await git("init")
        await git("-c", "user.name=ghpr-tests", "-c", "user.email=tests@ghpr.local", "commit", "--allow-empty", "-m", "initial")
        await git("checkout", "--detach")
        let repository = LocalRepository(directory: directory)

        await #expect(throws: LocalRepositoryError.detachedHead) {
            try await repository.currentBranch()
        }
    }
}
