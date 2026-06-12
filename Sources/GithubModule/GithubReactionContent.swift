import Foundation

/// The eight reactions GitHub supports, bridging the GraphQL enum (read)
/// and the REST content string (write).
package enum GithubReactionContent: String, Sendable, CaseIterable {
    case thumbsUp = "THUMBS_UP"
    case thumbsDown = "THUMBS_DOWN"
    case laugh = "LAUGH"
    case hooray = "HOORAY"
    case confused = "CONFUSED"
    case heart = "HEART"
    case rocket = "ROCKET"
    case eyes = "EYES"

    package var emoji: String {
        switch self {
        case .thumbsUp: "👍"
        case .thumbsDown: "👎"
        case .laugh: "😄"
        case .hooray: "🎉"
        case .confused: "😕"
        case .heart: "❤️"
        case .rocket: "🚀"
        case .eyes: "👀"
        }
    }

    /// The REST API's content identifier.
    package var restValue: String {
        switch self {
        case .thumbsUp: "+1"
        case .thumbsDown: "-1"
        case .laugh: "laugh"
        case .hooray: "hooray"
        case .confused: "confused"
        case .heart: "heart"
        case .rocket: "rocket"
        case .eyes: "eyes"
        }
    }
}
