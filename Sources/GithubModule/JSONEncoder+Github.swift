import Foundation

/// GitHub wire-format encoding configuration.
extension JSONEncoder {
    /// Encoder matching GitHub's wire format: snake_case keys.
    static var github: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
