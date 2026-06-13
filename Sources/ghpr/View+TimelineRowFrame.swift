import Foundation
import SwiftUI

extension View {
    /// Standard inset and width for rows hosted in the AppKit timeline table.
    func timelineRowFrame() -> some View {
        self
            .padding(.vertical, 7)
            .frame(maxWidth: 720, alignment: .leading)
    }
}
