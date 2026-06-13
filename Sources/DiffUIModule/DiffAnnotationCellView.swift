import AppKit
import Foundation
import SwiftUI

/// Table cell hosting caller-provided SwiftUI content (a review thread).
///
/// Annotation rows are rare, so cells are not recycled; each one keeps its
/// own hosting view and reports the height for the current table width.
final class DiffAnnotationCellView: NSView {
    private let hostingView: NSHostingView<AnyView>
    private var measuredHeights: [Int: CGFloat] = [:]

    init(content: AnyView) {
        hostingView = NSHostingView(rootView: content)
        super.init(frame: .zero)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    /// The content's ideal height when laid out at the given width.
    func height(forWidth width: CGFloat) -> CGFloat {
        let widthKey = max(1, Int(width.rounded(.toNearestOrAwayFromZero)))
        if let measuredHeight = measuredHeights[widthKey] {
            return measuredHeight
        }
        hostingView.frame.size.width = width
        let measuredHeight = hostingView.fittingSize.height
        measuredHeights[widthKey] = measuredHeight
        return measuredHeight
    }
}
