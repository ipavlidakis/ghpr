import Foundation
import GithubModule
import SwiftUI

/// The Checks tab: every check run with its status.
struct ChecksListView: View {
    let checkRuns: [GithubCheckRun]

    var body: some View {
        Group {
            if checkRuns.isEmpty {
                ContentUnavailableView(
                    "No checks",
                    systemImage: "checkmark.seal",
                    description: Text("This pull request has no reported check runs.")
                )
            } else {
                List(Array(checkRuns.enumerated()), id: \.offset) { _, run in
                    row(for: run)
                }
                .listStyle(.inset)
                .frame(maxWidth: 760)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    private func row(for run: GithubCheckRun) -> some View {
        HStack(spacing: 10) {
            Image(systemName: ChecksListView.symbol(for: run))
                .foregroundStyle(ChecksListView.color(for: run))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(statusText(for: run))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let htmlUrl = run.htmlUrl {
                Button {
                    open(htmlUrl)
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Open check")
            }
        }
        .padding(.vertical, 5)
    }

    private func statusText(for run: GithubCheckRun) -> String {
        (run.conclusion ?? run.status)
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    static func symbol(for run: GithubCheckRun) -> String {
        switch run.conclusion {
        case "success": "checkmark.circle.fill"
        case "failure", "timed_out": "xmark.circle.fill"
        case "cancelled": "slash.circle.fill"
        case "skipped", "neutral": "minus.circle.fill"
        case "action_required": "exclamationmark.circle.fill"
        default: run.status == "completed" ? "questionmark.circle" : "clock.fill"
        }
    }

    static func color(for run: GithubCheckRun) -> Color {
        switch run.conclusion {
        case "success": .green
        case "failure", "timed_out", "action_required": .red
        case "cancelled", "skipped", "neutral": .secondary
        default: run.status == "completed" ? .secondary : .orange
        }
    }
}
