import Foundation
import GithubModule
import SwiftUI

/// One pull request in the dashboard list.
struct DashRowView: View {
    let pullRequest: GithubPullRequest
    let isOpening: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: pullRequest.draft ? "circle.dashed" : "smallcircle.filled.circle")
                .foregroundStyle(pullRequest.draft ? Color.secondary : .green)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pullRequest.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    if pullRequest.draft {
                        Text("Draft")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .overlay(Capsule().strokeBorder(.separator, lineWidth: 1))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(pullRequest.labels.prefix(4), id: \.name) { label in
                        Text(label.name)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background((Color(hex: label.color) ?? .gray).opacity(0.25), in: .capsule)
                    }
                }
                HStack(spacing: 6) {
                    Text("#\(pullRequest.number)")
                    Text("by \(pullRequest.user?.login ?? "ghost")")
                    Text("·")
                    Text(pullRequest.head.ref)
                        .font(.caption.monospaced())
                    Text("·")
                    Text(pullRequest.updatedAt, format: .relative(presentation: .named))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if isOpening {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
