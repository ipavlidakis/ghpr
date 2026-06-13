import Foundation
import SwiftUI

/// SwiftUI content for a diff file header hosted by the virtualized table.
struct DiffFileHeaderRowView: View {
    let file: FileDiff
    let isCollapsed: Bool
    let isExpandable: Bool
    let hasActions: Bool
    let onCollapse: () -> Void
    let onViewedToggle: (Bool) -> Void
    let onCopy: () -> Void
    let onExpand: () -> Void
    let onMore: () -> Void

    @State private var isViewed: Bool

    init(
        file: FileDiff,
        isCollapsed: Bool,
        isViewed: Bool,
        isExpandable: Bool,
        hasActions: Bool,
        onCollapse: @escaping () -> Void,
        onViewedToggle: @escaping (Bool) -> Void,
        onCopy: @escaping () -> Void,
        onExpand: @escaping () -> Void,
        onMore: @escaping () -> Void
    ) {
        self.file = file
        self.isCollapsed = isCollapsed
        self.isExpandable = isExpandable
        self.hasActions = hasActions
        self.onCollapse = onCollapse
        self.onViewedToggle = onViewedToggle
        self.onCopy = onCopy
        self.onExpand = onExpand
        self.onMore = onMore
        _isViewed = State(initialValue: isViewed)
    }

    var body: some View {
        HStack(spacing: 7) {
            collapseButton

            iconButton("doc.on.doc", title: "Copy file name", action: onCopy)

            if isExpandable {
                iconButton("rectangle.expand.vertical", title: "Expand all lines", action: onExpand)
            }

            Spacer(minLength: 12)

            Button {
                viewedBinding.wrappedValue.toggle()
            } label: {
                Label("Viewed", systemImage: isViewed ? "checkmark.circle.fill" : "circle")
                    .frame(height: 30)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .accessibilityIdentifier("ghpr.files.header.viewed")
            .accessibilityLabel(isViewed ? "Mark \(title) as not viewed" : "Mark \(title) as viewed")
            .accessibilityValue(isViewed ? "Viewed" : "Not viewed")
            .accessibilityHint("Toggles viewed state for this file")

            if hasActions {
                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .frame(width: 30, height: 30)
                }
                .help("More actions")
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .accessibilityIdentifier("ghpr.files.header.more")
                .accessibilityLabel("More actions for \(title)")
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 8)
        .padding(.vertical, 5)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var collapseButton: some View {
        Button(action: onCollapse) {
            HStack(spacing: 7) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .frame(width: 28, height: 28)

                FileStatusBadge(status: file.status)

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                ChangeCountsLabel(additions: file.additions, deletions: file.deletions)
            }
            .contentShape(.rect)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .help(isCollapsed ? "Expand file" : "Collapse file")
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("ghpr.files.header.collapse")
        .accessibilityLabel(isCollapsed ? "Expand \(title)" : "Collapse \(title)")
        .accessibilityValue("\(file.status.accessibilityDescription), \(file.additions) additions, \(file.deletions) deletions")
    }

    private var viewedBinding: Binding<Bool> {
        Binding {
            isViewed
        } set: { newValue in
            isViewed = newValue
            onViewedToggle(newValue)
        }
    }

    private var title: String {
        if case .renamed(let from) = file.status {
            "\(from) → \(file.path)"
        } else {
            file.path
        }
    }

    private func iconButton(_ systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 30, height: 30)
        }
        .help(title)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.small)
        .accessibilityIdentifier("ghpr.files.header.\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
        .accessibilityLabel(title)
    }
}
