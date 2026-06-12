import Foundation
import AppKit
import Foundation

/// Shared visual constants for diff rendering (AppKit row host).
@MainActor
enum DiffStyle {
    static let rowHeight: CGFloat = 18
    static let codeFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    static let additionBackground = NSColor.systemGreen.withAlphaComponent(0.12)
    static let deletionBackground = NSColor.systemRed.withAlphaComponent(0.12)
    static let additionEmphasis = NSColor.systemGreen.withAlphaComponent(0.35)
    static let deletionEmphasis = NSColor.systemRed.withAlphaComponent(0.35)
    static let hunkHeaderBackground = NSColor.controlBackgroundColor

    /// Gutter column width in characters for this file's highest line number.
    nonisolated static func gutterDigits(for fileDiff: FileDiff) -> Int {
        let highestLineNumber = fileDiff.hunks.reduce(1) {
            max($0, $1.oldStart + $1.oldCount, $1.newStart + $1.newCount)
        }
        return max(3, String(highestLineNumber).count)
    }
}
