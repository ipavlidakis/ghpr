import Foundation
import SwiftTreeSitter
import TreeSitterBash
import TreeSitterC
import TreeSitterCPP
import TreeSitterGo
import TreeSitterJSON
import TreeSitterJavaScript
import TreeSitterKotlin
import TreeSitterMarkdown
import TreeSitterObjc
import TreeSitterPython
import TreeSitterRust
import TreeSitterSwift
import TreeSitterTypeScript
import TreeSitterYAML

/// The bundled tree-sitter grammars, resolved from a file-extension hint.
/// Anything else renders as plain text.
enum SupportedLanguage: Hashable {
    case swift, objc, c, cpp, kotlin, javascript, typescript, json, yaml, markdown, python, bash, rust, go

    init?(hint: String?) {
        switch hint {
        case "swift": self = .swift
        case "m", "mm": self = .objc
        case "c", "h": self = .c
        case "cpp", "cc", "cxx", "hpp", "hh": self = .cpp
        case "kt", "kts": self = .kotlin
        case "js", "jsx", "mjs", "cjs": self = .javascript
        case "ts", "tsx", "mts", "cts": self = .typescript
        case "json": self = .json
        case "yml", "yaml": self = .yaml
        case "md", "markdown": self = .markdown
        case "py": self = .python
        case "sh", "bash", "zsh": self = .bash
        case "rs": self = .rust
        case "go": self = .go
        default: return nil
        }
    }

    /// Loads the grammar and its bundled `highlights.scm`; `nil` when the
    /// bundle is missing, in which case the file renders unhighlighted.
    func makeConfiguration() -> LanguageConfiguration? {
        switch self {
        case .swift: Self.configuration(tree_sitter_swift(), "Swift")
        case .objc: Self.configuration(tree_sitter_objc(), "Objc")
        case .c: Self.configuration(tree_sitter_c(), "C")
        case .cpp: Self.configuration(tree_sitter_cpp(), "CPP")
        case .kotlin: Self.configuration(tree_sitter_kotlin(), "Kotlin")
        case .javascript: Self.configuration(tree_sitter_javascript(), "JavaScript")
        case .typescript: Self.configuration(tree_sitter_typescript(), "TypeScript")
        case .json: Self.configuration(tree_sitter_json(), "JSON")
        case .yaml: Self.configuration(tree_sitter_yaml(), "YAML")
        case .markdown: Self.configuration(tree_sitter_markdown(), "Markdown")
        case .python: Self.configuration(tree_sitter_python(), "Python")
        case .bash: Self.configuration(tree_sitter_bash(), "Bash")
        case .rust: Self.configuration(tree_sitter_rust(), "Rust")
        case .go: Self.configuration(tree_sitter_go(), "Go")
        }
    }

    private static func configuration(_ tsLanguage: OpaquePointer, _ name: String) -> LanguageConfiguration? {
        guard let queriesURL = queriesURL(bundleName: "TreeSitter\(name)_TreeSitter\(name)") else {
            return nil
        }
        return try? LanguageConfiguration(tsLanguage, name: name, queriesURL: queriesURL)
    }

    /// Finds a grammar's SPM resource bundle next to the running executable.
    ///
    /// SwiftTreeSitter's own bundle lookup assumes the Xcode layout
    /// (`Contents/Resources/queries`), but `swift build` produces flat
    /// bundles (`<bundle>/queries`), so both layouts are probed — relative
    /// to the host binary (the CLI) and its parent directory (test runners).
    private static func queriesURL(bundleName: String) -> URL? {
        let hostBundleURL = Bundle(for: DiffTableRowView.self).bundleURL
        let roots = [hostBundleURL, hostBundleURL.deletingLastPathComponent()]

        for root in roots {
            let bundle = root.appending(path: "\(bundleName).bundle")
            for queries in [bundle.appending(path: "queries"), bundle.appending(path: "Contents/Resources/queries")]
            where FileManager.default.isReadableFile(atPath: queries.appending(path: "highlights.scm").path) {
                return queries
            }
        }
        return nil
    }
}
