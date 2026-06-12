import Foundation

/// Persists which files the user marked as viewed, per pull request,
/// alongside a digest of each file's patch — a changed file invalidates
/// its own mark. Lives in `~/Library/Caches/ghpr/`: losing it only loses
/// review progress, which matches cache semantics.
actor ViewedFilesStore {
    private let fileURL: URL
    private var entries: [String: [String: String]]?

    init(fileURL: URL = ViewedFilesStore.defaultURL) {
        self.fileURL = fileURL
    }

    static var defaultURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "ghpr/viewed-files.json")
    }

    /// The stored viewed paths whose digests still match the current diff.
    func viewedPaths(in pullRequestKey: String, matching digests: [String: String]) -> Set<String> {
        let stored = load()[pullRequestKey] ?? [:]
        return Set(digests.compactMap { path, digest in
            stored[path] == digest ? path : nil
        })
    }

    func setViewed(_ isViewed: Bool, path: String, digest: String, in pullRequestKey: String) {
        var all = load()
        var entry = all[pullRequestKey] ?? [:]
        entry[path] = isViewed ? digest : nil
        all[pullRequestKey] = entry.isEmpty ? nil : entry
        entries = all

        // Best-effort persistence; review progress is reconstructible.
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(all) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() -> [String: [String: String]] {
        if let entries {
            return entries
        }
        let loaded = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([String: [String: String]].self, from: $0) } ?? [:]
        entries = loaded
        return loaded
    }
}
