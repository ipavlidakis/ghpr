import DiffUIModule
import Foundation

/// One locally-drafted inline comment, waiting in the review batch.
struct PendingComment: Identifiable, Sendable, Equatable {
    let id = UUID()
    let path: String
    let anchor: DiffLineAnchor
    let body: String
}
