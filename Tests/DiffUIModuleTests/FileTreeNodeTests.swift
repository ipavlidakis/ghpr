import Foundation
import Testing
@testable import DiffUIModule

/// Covers tree building and single-child directory chain compression.
@Suite("FileTreeNode")
struct FileTreeNodeTests {
    private func item(_ path: String) -> FileListItem {
        FileListItem(path: path, status: .modified, additions: 1, deletions: 0)
    }

    @Test("directories nest and files sort within them")
    func nesting() {
        let tree = FileTreeNode.tree(from: [
            item("Sources/App/Main.swift"),
            item("Sources/App/Helper.swift"),
            item("README.md"),
        ])

        // Directories first, then root files.
        #expect(tree.count == 2)
        #expect(tree[0].name == "Sources/App")
        #expect(tree[1].name == "README.md")
        #expect(tree[1].item != nil)

        let files = tree[0].children ?? []
        #expect(files.map(\.name) == ["Helper.swift", "Main.swift"])
    }

    @Test("file-less single-child directory chains compress inline")
    func chainCompression() {
        let tree = FileTreeNode.tree(from: [
            item("Packages/Cores/Logging/Sources/Logging/LogSubsystem.swift")
        ])

        #expect(tree.count == 1)
        #expect(tree[0].name == "Packages/Cores/Logging/Sources/Logging")
        #expect(tree[0].children?.first?.name == "LogSubsystem.swift")
    }

    @Test("a directory with a file stops the compression chain")
    func chainStopsAtFiles() {
        let tree = FileTreeNode.tree(from: [
            item("Sources/App/Models/User.swift"),
            item("Sources/App/App.swift"),
        ])

        #expect(tree[0].name == "Sources/App")
        // Directories sort before files: Models, then App.swift.
        let children = tree[0].children ?? []
        #expect(children.map(\.name) == ["Models", "App.swift"])
        #expect(children.first?.children?.first?.name == "User.swift")
    }

    @Test("orderedPaths walks directories first, files after, alphabetically")
    func orderedPaths() {
        let order = FileTreeNode.orderedPaths(from: [
            item("README.md"),
            item("Sources/App/Main.swift"),
            item("Sources/App/Helper.swift"),
            item("Sources/Zeta.swift"),
        ])

        #expect(order == [
            "Sources/App/Helper.swift",
            "Sources/App/Main.swift",
            "Sources/Zeta.swift",
            "README.md",
        ])
    }

    @Test("node ids are full paths, unique across the tree")
    func ids() {
        let tree = FileTreeNode.tree(from: [
            item("A/B/file1.swift"),
            item("A/C/file2.swift"),
        ])

        #expect(tree[0].id == "A")
        let children = tree[0].children ?? []
        #expect(children.map(\.id) == ["A/B", "A/C"])
    }
}
