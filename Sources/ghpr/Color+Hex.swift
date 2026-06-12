import Foundation
import SwiftUI

/// GitHub label colors arrive as bare hex strings (`d73a4a`).
extension Color {
    init?(hex: String?) {
        guard
            let hex,
            hex.count == 6,
            let value = UInt32(hex, radix: 16)
        else { return nil }

        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
