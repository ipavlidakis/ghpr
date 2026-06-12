import DiffUIModule
import Foundation
import GithubModule
import SwiftUI

/// The review window: GitHub-style header bar, overview and changed files in
/// the sidebar, and a continuous scroll through every file's diff — the
/// sidebar selection follows the scroll position, and selecting a file
/// scrolls to it. Composes DiffUIModule components and maps GithubModule
/// models onto them; the two modules never meet directly.
struct ReviewScreen: View {
    private let model: ReviewModel
    private let highlighter = SyntaxHighlighter()

    @State private var tab: ReviewTab = .conversation
    @State private var selectedPath: String?
    @State private var scrollTarget: DiffScrollTarget?
    @State private var composerTarget: DiffFileAnchor?
    @State private var isSubmitPopoverShown = false
    @State private var collapsedThreads: Set<String> = []

    init(model: ReviewModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            tabBar
            Divider()
            content
        }
        .alert("GitHub request failed", isPresented: errorShown) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .conversation:
            ReviewOverviewView(data: model.data)
        case .commits:
            CommitsListView(commits: model.data.commits)
        case .checks:
            ChecksListView(checkRuns: model.data.checkRuns)
        case .files:
            filesSplitView
        }
    }

    private var filesSplitView: some View {
        NavigationSplitView {
            FileListView(items: model.data.files.map(FileListItem.init), selectedPath: selectedPath) { item in
                selectedPath = item.path
                scrollTarget = DiffScrollTarget(path: item.path)
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            MultiFileDiffView(
                files: model.data.files,
                highlighter: highlighter,
                annotations: annotations,
                onLineClick: { path, line in
                    composerTarget = line.anchors.first.map { DiffFileAnchor(path: path, anchor: $0) }
                },
                onVisibleFileChange: { selectedPath = $0 },
                scrollTarget: scrollTarget
            )
        }
    }

    private var errorShown: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 4) {
            tabButton(.conversation, count: model.data.threads.count)
            tabButton(.commits, count: model.data.commits.count)
            tabButton(.checks, count: model.data.checkRuns.count)
            tabButton(.files, count: model.data.files.count)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func tabButton(_ target: ReviewTab, count: Int) -> some View {
        Button {
            tab = target
        } label: {
            HStack(spacing: 6) {
                Image(systemName: target.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(target.title)
                    .font(.callout.weight(tab == target ? .semibold : .regular))
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary.opacity(0.7), in: .capsule)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                tab == target ? AnyShapeStyle(.quaternary.opacity(0.55)) : AnyShapeStyle(.clear),
                in: .rect(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Header bar (title left, submit top-trailing, like GitHub)

    private var headerBar: some View {
        HStack(spacing: 12) {
            Text("\(model.data.pullRequest.title) ")
                .font(.headline)
            + Text("#\(model.data.pullRequest.number)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            submitButton
        }
        .lineLimit(1)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var submitButton: some View {
        Button {
            isSubmitPopoverShown = true
        } label: {
            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            } else if model.pendingComments.isEmpty {
                Text("Submit review")
            } else {
                Text("Submit review (\(model.pendingComments.count))")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(model.isBusy)
        .popover(isPresented: $isSubmitPopoverShown, arrowEdge: .bottom) {
            SubmitReviewView(
                pendingCount: model.pendingComments.count,
                isBusy: model.isBusy,
                onSubmit: { event, body in
                    isSubmitPopoverShown = false
                    Task { await model.submitReview(event: event, body: body) }
                },
                onCancel: { isSubmitPopoverShown = false }
            )
        }
    }

    // MARK: Annotations

    /// Everything pinned under diff lines across all files: existing threads
    /// (with reply/resolve/react), pending batch comments, and the composer.
    private var annotations: [DiffFileAnchor: AnyView] {
        var sections: [DiffFileAnchor: [AnyView]] = [:]

        for thread in model.data.threads where thread.line != nil && !thread.isOutdated {
            let anchor = DiffFileAnchor(
                path: thread.path,
                anchor: thread.diffSide == "LEFT" ? .old(thread.line!) : .new(thread.line!)
            )
            sections[anchor, default: []].append(AnyView(
                ReviewThreadView(
                    thread: thread,
                    pullRequestAuthor: model.data.pullRequest.user?.login,
                    isCollapsed: collapsedThreads.contains(thread.id),
                    onToggleCollapse: {
                        if !collapsedThreads.insert(thread.id).inserted {
                            collapsedThreads.remove(thread.id)
                        }
                    },
                    onReply: { body in Task { await model.reply(to: thread, body: body) } },
                    onResolve: { Task { await model.resolve(thread: thread) } },
                    onReact: { comment, reaction in Task { await model.react(to: comment, with: reaction) } }
                )
            ))
        }

        for comment in model.pendingComments {
            sections[DiffFileAnchor(path: comment.path, anchor: comment.anchor), default: []].append(AnyView(
                PendingCommentView(comment: comment) {
                    model.removePendingComment(id: comment.id)
                }
            ))
        }

        if let composerTarget {
            sections[composerTarget, default: []].append(AnyView(
                CommentComposerView(
                    onAddToReview: { body in
                        model.addPendingComment(path: composerTarget.path, anchor: composerTarget.anchor, body: body)
                        self.composerTarget = nil
                    },
                    onCommentNow: { body in
                        self.composerTarget = nil
                        Task { await model.addSingleComment(path: composerTarget.path, anchor: composerTarget.anchor, body: body) }
                    },
                    onCancel: { self.composerTarget = nil }
                )
            ))
        }

        return sections.mapValues { views in
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(views.enumerated()), id: \.offset) { _, view in
                        view
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                // Fill the hosted cell's width so cards pin to the leading
                // edge instead of centering.
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
}
