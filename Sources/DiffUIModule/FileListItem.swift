/// Input model of `FileListView`: one changed file and its change counts.
package struct FileListItem: Sendable, Equatable, Identifiable {
    package let path: String
    package let status: FileDiffStatus
    package let additions: Int
    package let deletions: Int

    package var id: String { path }

    package init(path: String, status: FileDiffStatus, additions: Int, deletions: Int) {
        self.path = path
        self.status = status
        self.additions = additions
        self.deletions = deletions
    }

    package init(_ fileDiff: FileDiff) {
        self.init(
            path: fileDiff.path,
            status: fileDiff.status,
            additions: fileDiff.additions,
            deletions: fileDiff.deletions
        )
    }
}
