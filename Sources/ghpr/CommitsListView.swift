import Foundation
import GithubModule
import SwiftUI

/// The Commits tab: every commit of the pull request, newest last.
struct CommitsListView: View {
    let commits: [GithubCommit]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(commits.enumerated()), id: \.element.sha) { index, commit in
                    row(for: commit)
                    if index < commits.count - 1 {
                        Divider()
                    }
                }
            }
            .background(.background.opacity(0.6), in: .rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.separator, lineWidth: 1)
            )
            .padding(20)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func row(for commit: GithubCommit) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(commit.summary)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let author = commit.authorName {
                        Text(author)
                            .font(.caption.weight(.medium))
                    }
                    if let date = commit.authoredAt {
                        Text(date, format: .relative(presentation: .named))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text(commit.shortSha)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
