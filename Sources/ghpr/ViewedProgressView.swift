import Foundation
import SwiftUI

/// GitHub's review-progress indicator: a small ring plus "N / M viewed".
struct ViewedProgressView: View {
    let viewed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.purple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 14, height: 14)
            Text("\(viewed) / \(total) viewed")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var progress: CGFloat {
        total > 0 ? CGFloat(viewed) / CGFloat(total) : 0
    }
}
