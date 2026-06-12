import Foundation

/// Semantic classes of code tokens the diff renderer colors.
package enum TokenKind: Sendable, Equatable {
    case keyword
    case string
    case comment
    case number
    case type
    case function
    case property
    case attribute

    /// Maps a tree-sitter highlights capture name (`keyword.function`,
    /// `string.special`, …) onto a renderable kind. Unmapped captures render
    /// as plain text.
    package init?(captureName: String) {
        let root = captureName.split(separator: ".").first.map(String.init) ?? captureName
        switch root {
        case "keyword", "include", "conditional", "repeat", "boolean":
            self = .keyword
        case "string", "text":
            self = .string
        case "comment":
            self = .comment
        case "number", "float", "integer":
            self = .number
        case "type", "constructor", "class":
            self = .type
        case "function", "method":
            self = .function
        case "property", "field", "variable", "constant", "parameter":
            self = .property
        case "attribute", "decorator", "macro", "label":
            self = .attribute
        default:
            return nil
        }
    }
}
