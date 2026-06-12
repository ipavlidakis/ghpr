import Foundation
import Testing
import DiffUIModule

/// Validates the parser against the captured PR diff and handcrafted edge cases.
@Suite("UnifiedDiffParser")
struct UnifiedDiffParserTests {
    private let parser = UnifiedDiffParser()

    // MARK: Real captured diff (apple/swift-argument-parser PR 908)

    @Test("the real PR diff matches the PR's reported counters")
    func realDiff() throws {
        let files = parser.parse(try Fixture.string("pull-request.diff"))

        // GitHub reported changed_files: 5, additions: 34, deletions: 12 for this PR.
        #expect(files.count == 5)
        #expect(files.reduce(0) { $0 + $1.additions } == 34)
        #expect(files.reduce(0) { $0 + $1.deletions } == 12)
        #expect(files.allSatisfy { $0.status == .modified })
        #expect(files.allSatisfy { !$0.isBinary })
        #expect(files.first?.languageHint == "yml")
        #expect(files.count(where: { $0.languageHint == "swift" }) == 4)
        // Paths containing spaces survive parsing.
        #expect(files.map(\.path).contains("Sources/ArgumentParser/Parsable Types/AsyncParsableCommand.swift"))
    }

    @Test("hunk line numbers are consistent with hunk headers")
    func lineNumbers() throws {
        let files = parser.parse(try Fixture.string("pull-request.diff"))

        for hunk in files.flatMap(\.hunks) {
            var expectedOld = hunk.oldStart
            var expectedNew = hunk.newStart
            for line in hunk.lines {
                switch line.kind {
                case .context:
                    #expect(line.oldLineNumber == expectedOld)
                    #expect(line.newLineNumber == expectedNew)
                    expectedOld += 1
                    expectedNew += 1
                case .deletion:
                    #expect(line.oldLineNumber == expectedOld)
                    #expect(line.newLineNumber == nil)
                    expectedOld += 1
                case .addition:
                    #expect(line.oldLineNumber == nil)
                    #expect(line.newLineNumber == expectedNew)
                    expectedNew += 1
                }
            }
            #expect(expectedOld == hunk.oldStart + hunk.oldCount)
            #expect(expectedNew == hunk.newStart + hunk.newCount)
        }
    }

    // MARK: Handcrafted edge cases

    @Test("added file")
    func addedFile() {
        let diff = """
        diff --git a/new.txt b/new.txt
        new file mode 100644
        index 0000000..3b18e51
        --- /dev/null
        +++ b/new.txt
        @@ -0,0 +1,2 @@
        +hello
        +world
        """

        let files = parser.parse(diff)

        let file = files.first
        #expect(files.count == 1)
        #expect(file?.path == "new.txt")
        #expect(file?.status == .added)
        #expect(file?.additions == 2)
        #expect(file?.deletions == 0)
        #expect(file?.hunks.first?.lines.first?.newLineNumber == 1)
    }

    @Test("deleted file keeps its old path")
    func deletedFile() {
        let diff = """
        diff --git a/gone.txt b/gone.txt
        deleted file mode 100644
        index 3b18e51..0000000
        --- a/gone.txt
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -hello
        -world
        """

        let files = parser.parse(diff)

        #expect(files.first?.path == "gone.txt")
        #expect(files.first?.status == .deleted)
        #expect(files.first?.deletions == 2)
    }

    @Test("rename without content changes")
    func pureRename() {
        let diff = """
        diff --git a/old-name.txt b/new-name.txt
        similarity index 100%
        rename from old-name.txt
        rename to new-name.txt
        """

        let files = parser.parse(diff)

        #expect(files.first?.path == "new-name.txt")
        #expect(files.first?.status == .renamed(from: "old-name.txt"))
        #expect(files.first?.hunks.isEmpty == true)
    }

    @Test("binary file")
    func binaryFile() {
        let diff = """
        diff --git a/image.png b/image.png
        index 12ab34c..56de78f 100644
        Binary files a/image.png and b/image.png differ
        """

        let files = parser.parse(diff)

        #expect(files.first?.path == "image.png")
        #expect(files.first?.isBinary == true)
        #expect(files.first?.hunks.isEmpty == true)
    }

    @Test("omitted hunk counts default to 1")
    func singleLineHunkCounts() {
        let diff = """
        diff --git a/one.txt b/one.txt
        index 12ab34c..56de78f 100644
        --- a/one.txt
        +++ b/one.txt
        @@ -1 +1 @@
        -old
        +new
        """

        let hunk = parser.parse(diff).first?.hunks.first

        #expect(hunk?.oldCount == 1)
        #expect(hunk?.newCount == 1)
        #expect(hunk?.lines.count == 2)
    }

    @Test("no-newline markers are skipped")
    func noNewlineMarker() {
        let diff = """
        diff --git a/file.txt b/file.txt
        index 12ab34c..56de78f 100644
        --- a/file.txt
        +++ b/file.txt
        @@ -1 +1 @@
        -old
        \\ No newline at end of file
        +new
        \\ No newline at end of file
        """

        let hunk = parser.parse(diff).first?.hunks.first

        #expect(hunk?.lines.count == 2)
        #expect(hunk?.lines.map(\.kind) == [.deletion, .addition])
    }

    @Test("empty context lines stay context lines")
    func emptyContextLine() {
        let diff = "diff --git a/f.txt b/f.txt\n--- a/f.txt\n+++ b/f.txt\n@@ -1,3 +1,3 @@\n a\n\n-b\n+c"

        let hunk = parser.parse(diff).first?.hunks.first

        #expect(hunk?.lines.map(\.kind) == [.context, .context, .deletion, .addition])
        #expect(hunk?.lines[1].text == "")
    }

    @Test("hunk section headings are preserved")
    func hunkHeading() {
        let diff = """
        diff --git a/code.swift b/code.swift
        --- a/code.swift
        +++ b/code.swift
        @@ -10,3 +10,4 @@ extension Foo {
         context
        +added
         context
         context
        """

        let hunk = parser.parse(diff).first?.hunks.first

        #expect(hunk?.header == "@@ -10,3 +10,4 @@ extension Foo {")
        #expect(hunk?.oldStart == 10)
        #expect(hunk?.newStart == 10)
    }

    @Test("garbage input parses to nothing")
    func garbage() {
        #expect(parser.parse("not a diff at all\njust text\n").isEmpty)
        #expect(parser.parse("").isEmpty)
    }
}
