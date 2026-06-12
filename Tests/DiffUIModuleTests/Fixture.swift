import Foundation

/// Loads diff payloads bundled with the test target.
enum Fixture {
    struct NotFound: Error {
        let name: String
    }

    static func string(_ filename: String) throws -> String {
        guard let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Fixtures") else {
            throw NotFound(name: filename)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
