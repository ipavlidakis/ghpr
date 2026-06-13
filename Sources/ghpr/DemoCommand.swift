import ArgumentParser
import DiffUIModule
import Foundation

/// Hidden command rendering the bundled large patch in a window — the
/// AppKit-from-CLI and renderer performance validation path.
struct DemoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "demo",
        abstract: "Render the bundled demo patch in a native window.",
        shouldDisplay: false
    )

    func run() throws {
        guard let url = Bundle.module.url(forResource: "demo", withExtension: "diff") else {
            throw ValidationError("The demo diff is missing from the build.")
        }
        let diff = try String(contentsOf: url, encoding: .utf8)
        let files = UnifiedDiffParser().parse(diff)

        // A synchronous ParsableCommand runs on the main thread.
        MainActor.assumeIsolated {
            AppBootstrap.run(
                title: "ghpr demo — \(files.count) files",
                content: DemoScreen(files: files)
            )
        }
    }
}
