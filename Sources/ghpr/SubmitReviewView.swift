import Foundation
import GithubModule
import SwiftUI

/// GitHub's "Finish your review" popover: summary, verdict, submit.
struct SubmitReviewView: View {
    let pendingCount: Int
    let isBusy: Bool
    let onSubmit: (GithubReviewEvent, String) -> Void
    let onCancel: () -> Void

    @State private var event: GithubReviewEvent = .comment
    @State private var summary = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Finish your review")
                .font(.headline)

            summaryEditor

            VStack(alignment: .leading, spacing: 10) {
                VerdictOption(
                    title: "Comment",
                    subtitle: "Submit general feedback without explicit approval.",
                    isSelected: event == .comment
                ) { event = .comment }
                VerdictOption(
                    title: "Approve",
                    subtitle: "Submit feedback and approve merging these changes.",
                    isSelected: event == .approve
                ) { event = .approve }
                VerdictOption(
                    title: "Request changes",
                    subtitle: "Submit feedback suggesting changes.",
                    isSelected: event == .requestChanges
                ) { event = .requestChanges }
            }

            if pendingCount > 0 {
                Text("Includes \(pendingCount) pending inline comment\(pendingCount == 1 ? "" : "s").")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if event == .requestChanges, !isValid {
                Text("Requesting changes needs a summary.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                Button {
                    onSubmit(event, summary.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Submit review")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isBusy || !isValid)
            }
        }
        .padding(16)
        .frame(width: 380)
    }

    private var summaryEditor: some View {
        TextEditor(text: $summary)
            .font(.callout)
            .frame(height: 90)
            .scrollContentBackground(.hidden)
            .padding(6)
            .background(.background, in: .rect(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.separator, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if summary.isEmpty {
                    Text("Leave a comment")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 6)
                        .padding(.leading, 10)
                        .allowsHitTesting(false)
                }
            }
    }

    /// GitHub rejects REQUEST_CHANGES without a body.
    private var isValid: Bool {
        event != .requestChanges || !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// One selectable verdict row: radio indicator, title, description.
    private struct VerdictOption: View {
        let title: String
        let subtitle: String
        let isSelected: Bool
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.callout.weight(.medium))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
