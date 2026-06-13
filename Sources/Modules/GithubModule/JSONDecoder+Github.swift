import Foundation

/// GitHub wire-format decoding configuration.
extension JSONDecoder {
    /// Decoder matching GitHub's wire format: snake_case keys and ISO 8601 dates.
    static var github: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
