import Foundation
import SwiftUI

/// SwiftUI title pill shown in the native window toolbar.
struct WindowTitleView: View {
    /// Repository title displayed in the toolbar.
    let title: String

    private let spacing = LayoutSpacing()

    /// Creates a title pill.
    init(title: String) {
        self.title = title
    }

    /// Glass title pill content.
    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.medium)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, spacing.large)
            .padding(.vertical, spacing.small)
            .glassEffect(.regular, in: .capsule)
    }
}
