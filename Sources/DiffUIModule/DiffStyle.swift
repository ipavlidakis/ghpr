import SwiftUI

/// Shared visual constants for diff rendering.
enum DiffStyle {
    static let codeFont = Font.system(size: 12, design: .monospaced)

    static let additionBackground = Color.green.opacity(0.12)
    static let deletionBackground = Color.red.opacity(0.12)
    static let additionEmphasis = Color.green.opacity(0.35)
    static let deletionEmphasis = Color.red.opacity(0.35)

    static func gutterWidth(for fileDiff: FileDiff) -> CGFloat {
        let highestLineNumber = fileDiff.hunks.reduce(1) {
            max($0, $1.oldStart + $1.oldCount, $1.newStart + $1.newCount)
        }
        let digits = max(3, String(highestLineNumber).count)
        return CGFloat(digits) * 8 + 8
    }
}
