import Foundation

/// `--detach` support: re-execs ghpr as a disowned background child (with
/// the flag stripped) and exits the parent, handing the terminal back
/// immediately while the window lives on.
enum Detach {
    static func relaunchInBackground() throws -> Never {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        process.arguments = Array(CommandLine.arguments.dropFirst()).filter { $0 != "--detach" }
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        exit(0)
    }
}
