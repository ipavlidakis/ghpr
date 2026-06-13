import Foundation

/// Loads captured GitHub API payloads bundled with the test target.
enum Fixture {
    struct NotFound: Error {
        let name: String
    }

    static func data(_ filename: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Fixtures") else {
            throw NotFound(name: filename)
        }
        return try Data(contentsOf: url)
    }
}
