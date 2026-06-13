import Foundation
import SwiftUI

/// Adaptive card surface for review metadata and conversations.
struct ReviewSurface: ViewModifier {
    var fill: AnyShapeStyle = AnyShapeStyle(.background.secondary)
    var border: AnyShapeStyle = AnyShapeStyle(.separator)
    var cornerRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(fill, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(border, lineWidth: 1)
            }
    }
}
