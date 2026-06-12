import Foundation
import GithubModule
import SwiftUI

/// The Checks tab: every check run with its status.
struct ChecksListView: View {
    let checkRuns: [GithubCheckRun]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(checkRuns.enumerated()), id: \.offset) { index, run in
                    row(for: run)
                    if index < checkRuns.count - 1 {
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

    private func row(for run: GithubCheckRun) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ChecksListView.symbol(for: run))
                .foregroundStyle(ChecksListView.color(for: run))
            Text(run.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text(run.conclusion ?? run.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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
