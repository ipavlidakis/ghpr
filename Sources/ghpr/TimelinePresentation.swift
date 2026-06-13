import Foundation

/// Visible timeline window: leading items, hidden middle, revealed middle,
/// then trailing items.
struct TimelinePresentation {
    let hiddenStart: Int
    let revealedStart: Int
    let hiddenEnd: Int
}
