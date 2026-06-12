import AppKit
import Foundation

/// Opens a web URL in the default browser.
@MainActor
func open(_ url: String) {
    guard let url = URL(string: url) else { return }
    NSWorkspace.shared.open(url)
}
