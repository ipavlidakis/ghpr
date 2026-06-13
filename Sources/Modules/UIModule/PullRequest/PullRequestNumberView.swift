import Foundation
import SwiftUI

/// Pull request number pill for the title toolbar.
package struct PullRequestNumberView: View {
    /// Pull request number.
    package let number: Int

    private let spacing = LayoutSpacing()

    /// Creates a pull request number pill.
    package init(number: Int) {
        self.number = number
    }

    /// Number pill content.
    package var body: some View {
        Text("#\(number)")
            .font(.title3)
            .fontWeight(.medium)
            .lineLimit(1)
            .padding(.horizontal, spacing.medium)
            .padding(.vertical, spacing.small)
            .glassEffect(.regular, in: .capsule)
    }
}
