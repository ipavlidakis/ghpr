import Foundation

extension FileDiffStatus {
    var accessibilityDescription: String {
        switch self {
        case .added:
            "Added"
        case .deleted:
            "Deleted"
        case .modified:
            "Modified"
        case .renamed(let from):
            "Renamed from \(from)"
        }
    }
}
