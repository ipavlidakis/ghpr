import Foundation

/// The review window's GitHub-style tabs.
enum ReviewTab: Hashable, CaseIterable {
    case conversation
    case commits
    case checks
    case files

    var title: String {
        switch self {
        case .conversation: "Conversation"
        case .commits: "Commits"
        case .checks: "Checks"
        case .files: "Files changed"
        }
    }

    var systemImage: String {
        switch self {
        case .conversation: "bubble.left.and.bubble.right"
        case .commits: "arrow.triangle.merge"
        case .checks: "checkmark.circle"
        case .files: "doc.text"
        }
    }
}
