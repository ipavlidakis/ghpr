import Foundation
import SwiftUI

/// Compact separator for timeline ranges hidden for performance.
struct HiddenTimelineItemsView: View {
    let count: Int
    let onLoadMore: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            separator
            VStack(spacing: 5) {
                Text("\(count) hidden item\(count == 1 ? "" : "s")")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button("Load more...") {
                    onLoadMore()
                }
                .buttonStyle(.link)
                .font(.callout.weight(.semibold))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: .rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.separator.opacity(0.8), lineWidth: 1)
            }
            separator
        }
        .padding(.vertical, 12)
    }

    private var separator: some View {
        Rectangle()
            .fill(.separator.opacity(0.65))
            .frame(height: 1)
    }
}
