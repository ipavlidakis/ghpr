import Foundation
import GithubModule
import SwiftUI

/// The Commits tab: every commit of the pull request, newest last.
struct CommitsListView: View {
    let commits: [GithubCommit]

    var body: some View {
        Group {
            if commits.isEmpty {
                ContentUnavailableView(
                    "No commits",
                    systemImage: "arrow.triangle.merge",
                    description: Text("No commits were returned for this pull request.")
                )
            } else {
                List(commits, id: \.sha) { commit in
                    row(for: commit)
                }
                .listStyle(.inset)
                .frame(maxWidth: 760)
                .accessibilityIdentifier("ghpr.commits.list")
                .accessibilityLabel("Commits")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    private func row(for commit: GithubCommit) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(.secondary)
                .frame(width: 18)
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
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.background.tertiary, in: .rect(cornerRadius: 5))
        }
        .padding(.vertical, 5)
    }
}
