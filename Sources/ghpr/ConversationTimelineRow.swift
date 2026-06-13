import Foundation

/// One virtualized row in the conversation timeline table.
enum ConversationTimelineRow: Identifiable, Equatable {
    case header
    case description
    case item(index: Int)
    case hidden(count: Int)
    case pending

    var id: String {
        switch self {
        case .header:
            "header"
        case .description:
            "description"
        case .item(let index):
            "item-\(index)"
        case .hidden(let count):
            "hidden-\(count)"
        case .pending:
            "pending"
        }
    }
}
