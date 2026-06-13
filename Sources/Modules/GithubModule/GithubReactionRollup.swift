import Foundation

/// The REST `reactions` summary object: a count per emoji.
package struct GithubReactionRollup: Sendable, Equatable, Decodable {
    package let thumbsUp: Int?
    package let thumbsDown: Int?
    package let laugh: Int?
    package let hooray: Int?
    package let confused: Int?
    package let heart: Int?
    package let rocket: Int?
    package let eyes: Int?

    private enum CodingKeys: String, CodingKey {
        case thumbsUp = "+1"
        case thumbsDown = "-1"
        case laugh, hooray, confused, heart, rocket, eyes
    }

    /// The non-zero counts as displayable reactions.
    package var reactions: [GithubReaction] {
        let counts: [(GithubReactionContent, Int?)] = [
            (.thumbsUp, thumbsUp), (.thumbsDown, thumbsDown), (.laugh, laugh), (.hooray, hooray),
            (.confused, confused), (.heart, heart), (.rocket, rocket), (.eyes, eyes),
        ]
        return counts.compactMap { content, count in
            guard let count, count > 0 else { return nil }
            return GithubReaction(content: content, count: count)
        }
    }
}
