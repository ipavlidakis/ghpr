import Foundation

/// Runs async work from the synchronous CLI entry point by pumping the main
/// run loop until it finishes.
///
/// The executable's main must stay synchronous: a Swift-async main parks the
/// main thread in the concurrency drain loop, and once `NSApplication.run()`
/// starts inside it, MainActor continuations starve — awaits never resume in
/// the UI. With a synchronous main, MainActor jobs flow through the main
/// dispatch queue, which both this pump and AppKit's run loop service.
enum AsyncBridge {
    @MainActor
    private final class ResultBox<Success> {
        var result: Result<Success, any Error>?
    }

    static func run<Success: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Success
    ) throws -> Success {
        try MainActor.assumeIsolated {
            let box = ResultBox<Success>()

            Task { @MainActor in
                do {
                    box.result = .success(try await operation())
                } catch {
                    box.result = .failure(error)
                }
                CFRunLoopStop(CFRunLoopGetMain())
            }

            while box.result == nil {
                CFRunLoopRun()
            }
            return try box.result!.get()
        }
    }
}
