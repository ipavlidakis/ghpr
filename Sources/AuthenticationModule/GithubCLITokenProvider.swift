import Foundation

/// Borrows the token of an installed, signed-in `gh` CLI.
///
/// This is a convenience source only, never a dependency: any failure
/// (gh not installed, not signed in) silently resolves to no token.
package enum GithubCLITokenProvider {
    package static func token() async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "token"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        let started = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            process.terminationHandler = { _ in continuation.resume(returning: true) }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }

        guard started, process.terminationStatus == 0 else { return nil }

        // The process has exited, so the pipe already holds all output and this read returns immediately.
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let token = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }
}
