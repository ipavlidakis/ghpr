import Foundation
import GithubModule
import SwiftUI

/// The submit popover: verdict, optional summary, and the batch size.
struct SubmitReviewView: View {
    let pendingCount: Int
    let isBusy: Bool
    let onSubmit: (GithubReviewEvent, String) -> Void

    @State private var event: GithubReviewEvent = .comment
    @State private var body_: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submit review")
                .font(.headline)

            Picker("Verdict", selection: $event) {
                Text("Comment").tag(GithubReviewEvent.comment)
                Text("Approve").tag(GithubReviewEvent.approve)
                Text("Request changes").tag(GithubReviewEvent.requestChanges)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            TextEditor(text: $body_)
                .font(.callout)
                .frame(width: 320, height: 100)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background, in: .rect(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.separator, lineWidth: 1)
                )

            if pendingCount > 0 {
                Text("Includes \(pendingCount) pending inline comment\(pendingCount == 1 ? "" : "s").")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onSubmit(event, body_.trimmingCharacters(in: .whitespacesAndNewlines))
            } label: {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Submit")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy || !isValid)

            if event == .requestChanges, !isValid {
                Text("Requesting changes needs a summary.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
    }

    /// GitHub rejects REQUEST_CHANGES without a body.
    private var isValid: Bool {
        event != .requestChanges || !body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
