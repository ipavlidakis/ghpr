import Foundation

/// Dashboard PR filters.
enum DashFilter: Hashable, CaseIterable {
    case all
    case mine
    case reviewRequested

    var title: String {
        switch self {
        case .all: "All"
        case .mine: "Mine"
        case .reviewRequested: "Review requested"
        }
    }
}
