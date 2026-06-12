import Foundation
import Testing
@testable import ghpr

/// Round-trips viewed marks through a temp file and checks digest invalidation.
@Suite("ViewedFilesStore")
struct ViewedFilesStoreTests {
    private let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "ghpr-tests-\(UUID().uuidString)/viewed.json")

    @Test("a viewed mark persists across store instances while the digest matches")
    func persistence() async {
        let store = ViewedFilesStore(fileURL: fileURL)
        await store.setViewed(true, path: "A.swift", digest: "abc", in: "o/r#1")

        let reloaded = ViewedFilesStore(fileURL: fileURL)
        let viewed = await reloaded.viewedPaths(in: "o/r#1", matching: ["A.swift": "abc"])

        #expect(viewed == ["A.swift"])
    }

    @Test("a changed digest invalidates the mark")
    func digestInvalidation() async {
        let store = ViewedFilesStore(fileURL: fileURL)
        await store.setViewed(true, path: "A.swift", digest: "abc", in: "o/r#1")

        let viewed = await store.viewedPaths(in: "o/r#1", matching: ["A.swift": "DIFFERENT"])

        #expect(viewed.isEmpty)
    }

    @Test("unmarking removes the entry")
    func unmark() async {
        let store = ViewedFilesStore(fileURL: fileURL)
        await store.setViewed(true, path: "A.swift", digest: "abc", in: "o/r#1")
        await store.setViewed(false, path: "A.swift", digest: "abc", in: "o/r#1")

        let viewed = await store.viewedPaths(in: "o/r#1", matching: ["A.swift": "abc"])

        #expect(viewed.isEmpty)
    }

    @Test("marks are scoped per pull request")
    func scoping() async {
        let store = ViewedFilesStore(fileURL: fileURL)
        await store.setViewed(true, path: "A.swift", digest: "abc", in: "o/r#1")

        let other = await store.viewedPaths(in: "o/r#2", matching: ["A.swift": "abc"])

        #expect(other.isEmpty)
    }
}
