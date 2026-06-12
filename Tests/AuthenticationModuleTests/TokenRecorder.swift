import Foundation

/// Counts invocations so tests can assert lower-priority sources are never consulted.
actor TokenRecorder {
    private let result: String?
    private(set) var callCount = 0

    init(result: String?) {
        self.result = result
    }

    func provide() -> String? {
        callCount += 1
        return result
    }
}
