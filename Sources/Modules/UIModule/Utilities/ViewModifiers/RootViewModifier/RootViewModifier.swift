import Foundation
import SwiftUI

/// Applies the shared root window treatment for SwiftUI-hosted content.
private struct RootViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.background, ignoresSafeAreaEdges: .all)

    }
}

extension View {
    /// Applies the shared root window treatment.
    func rootView() -> some View {
        modifier(RootViewModifier())
    }
}
