import Foundation
import GithubModule
import SwiftUI

/// A submitted review in the timeline: verdict row, plus the summary
/// text as a card when the review has one.
struct ConversationReviewView: View {
    let review: GithubReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 18)
                AvatarView(urlString: review.authorAvatarURL, size: 20)
                Text(review.authorLogin ?? "ghost")
                    .font(.callout.weight(.semibold))
                Text(verdict)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(review.submittedAt, format: .relative(presentation: .named))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if !review.body.isEmpty {
                DeferredMarkdownView(text: review.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(ReviewSurface())
                    .padding(.leading, 24)
            }
        }
    }

    private var verdict: String {
        switch review.state {
        case "approved": "approved these changes"
        case "changes_requested": "requested changes"
        case "dismissed": "submitted a review that was later dismissed"
        default: "reviewed"
        }
    }

    private var icon: String {
        switch review.state {
        case "approved": "checkmark.circle.fill"
        case "changes_requested": "plusminus.circle.fill"
        default: "eye"
        }
    }

    private var iconColor: Color {
        switch review.state {
        case "approved": .green
        case "changes_requested": .red
        default: .secondary
        }
    }
}
