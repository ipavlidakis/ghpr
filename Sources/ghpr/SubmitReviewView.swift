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

            verdictPicker

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
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
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
                .buttonStyle(.glassProminent)
                .tint(.green)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(isBusy || !isValid)
            }
        }
        .padding(16)
        .frame(width: 380)
    }

    private var verdictPicker: some View {
        Picker("Verdict", selection: $event) {
            Text("Comment").tag(GithubReviewEvent.comment)
            Text("Approve").tag(GithubReviewEvent.approve)
            Text("Request changes").tag(GithubReviewEvent.requestChanges)
        }
        .pickerStyle(.radioGroup)
        .controlSize(.small)
    }

    private var summaryEditor: some View {
        TextEditor(text: $summary)
            .font(.callout)
            .frame(height: 90)
            .scrollContentBackground(.hidden)
            .padding(6)
            .modifier(ReviewSurface(cornerRadius: 6))
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

}
