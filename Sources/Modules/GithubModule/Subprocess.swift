import Foundation

/// Runs a command and captures its trimmed standard output.
enum Subprocess {
    struct Result {
        let status: Int32
        let output: String

        var succeeded: Bool { status == 0 }
    }

    static func run(_ arguments: [String]) async -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
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
        guard started else { return Result(status: -1, output: "") }

        // The process has exited, so the pipe already holds all output and this read returns immediately.
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return Result(status: process.terminationStatus, output: text)
    }
}
