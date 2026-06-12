import Foundation
import GithubModule
import SwiftUI

/// A commit pushed to the PR branch: message and short SHA on one line.
struct ConversationCommitRowView: View {
    let commit: GithubTimelineCommit

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "smallcircle.filled.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(commit.message.components(separatedBy: "\n").first ?? "")
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            Text(commit.sha.prefix(7))
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
}
