import AppKit
import Foundation
import SwiftUI

/// AppKit table cell that hosts a SwiftUI pull request row without contributing intrinsic width.
@MainActor
final class DashboardPullRequestCellView: NSTableCellView {
    private let hostingView: NSHostingView<DashboardPullRequestRow>

    /// Creates a table cell hosting a SwiftUI pull request row.
    init(rowView: DashboardPullRequestRow) {
        hostingView = NSHostingView(rootView: rowView)
        super.init(frame: .zero)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hostingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    /// Replaces the hosted SwiftUI row.
    func update(rowView: DashboardPullRequestRow) {
        hostingView.rootView = rowView
        hostingView.invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        let intrinsicHeight = hostingView.intrinsicContentSize.height
        let hostedHeight = intrinsicHeight == NSView.noIntrinsicMetric ? hostingView.fittingSize.height : intrinsicHeight
        return NSSize(width: NSView.noIntrinsicMetric, height: hostedHeight)
    }
}
