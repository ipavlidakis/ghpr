import Foundation

/// One node of the changed-files tree: a directory (with children) or a
/// file (with its list item). Directory chains with no files and a single
/// subdirectory render inline as one node ("Sources/App/Models"), like
/// GitHub's file tree.
struct FileTreeNode: Identifiable {
    let id: String
    /// Display name: the path component, or the compressed chain for
    /// single-child directories.
    let name: String
    /// Present on file nodes only.
    let item: FileListItem?
    /// Present on directory nodes only.
    let children: [FileTreeNode]?

    static func tree(from items: [FileListItem]) -> [FileTreeNode] {
        final class Directory {
            var directories: [String: Directory] = [:]
            var files: [FileListItem] = []
        }

        let root = Directory()
        for item in items {
            let components = item.path.split(separator: "/").map(String.init)
            var current = root
            for component in components.dropLast() {
                if let next = current.directories[component] {
                    current = next
                } else {
                    let next = Directory()
                    current.directories[component] = next
                    current = next
                }
            }
            current.files.append(item)
        }

        func nodes(of directory: Directory, pathPrefix: String) -> [FileTreeNode] {
            var result: [FileTreeNode] = []

            for (name, subdirectory) in directory.directories.sorted(by: { $0.key < $1.key }) {
                var displayName = name
                var path = pathPrefix + name
                var current = subdirectory

                // Compress chains of file-less single-subdirectory levels.
                while current.files.isEmpty, current.directories.count == 1,
                      let (childName, child) = current.directories.first {
                    displayName += "/" + childName
                    path += "/" + childName
                    current = child
                }

                result.append(FileTreeNode(
                    id: path,
                    name: displayName,
                    item: nil,
                    children: nodes(of: current, pathPrefix: path + "/")
                ))
            }

            for file in directory.files.sorted(by: { $0.path < $1.path }) {
                result.append(FileTreeNode(
                    id: file.path,
                    name: file.path.split(separator: "/").last.map(String.init) ?? file.path,
                    item: file,
                    children: nil
                ))
            }

            return result
        }

        return nodes(of: root, pathPrefix: "")
    }
}
