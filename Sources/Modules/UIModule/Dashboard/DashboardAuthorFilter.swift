import Foundation

/// Author-oriented dashboard filters.
package enum DashboardAuthorFilter: String, CaseIterable, Identifiable, Sendable {
    case mine
    case askedForReview
    case all

    /// Stable identity for picker and menu controls.
    package var id: String { rawValue }

    /// User-facing filter title.
    package var title: String {
        switch self {
        case .mine:
            "Mine"
        case .askedForReview:
            "Asked for review"
        case .all:
            "All"
        }
    }
}
