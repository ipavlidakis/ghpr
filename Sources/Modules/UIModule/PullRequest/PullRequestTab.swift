import Foundation

/// Primary pull request detail tabs.
package enum PullRequestTab: String, CaseIterable, Identifiable, Sendable {
    case conversations
    case commits
    case checks
    case filesChanged

    /// Stable identity for tab controls.
    package var id: String { rawValue }

    /// User-facing tab title.
    package var title: String {
        switch self {
        case .conversations:
            "Conversations"
        case .commits:
            "Commits"
        case .checks:
            "Checks"
        case .filesChanged:
            "Files Changed"
        }
    }
}
