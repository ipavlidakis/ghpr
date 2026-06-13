import Foundation

/// One concrete reaction entry returned by GitHub's REST reactions endpoints.
package struct GithubCommentReaction: Sendable, Equatable, Decodable {
    package let id: Int
    package let user: GithubUser
    package let content: GithubReactionContent

    private enum CodingKeys: String, CodingKey {
        case id, user, content
    }

    package init(id: Int, user: GithubUser, content: GithubReactionContent) {
        self.id = id
        self.user = user
        self.content = content
    }

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        user = try container.decode(GithubUser.self, forKey: .user)
        let restValue = try container.decode(String.self, forKey: .content)
        guard let content = GithubReactionContent(restValue: restValue) else {
            throw DecodingError.dataCorruptedError(forKey: .content, in: container, debugDescription: "Unsupported reaction content")
        }
        self.content = content
    }
}
