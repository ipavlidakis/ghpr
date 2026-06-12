import Foundation
import GithubModule
import SwiftUI

/// The dashboard window: the repo's open pull requests with filters;
/// selecting one opens a review window in this process.
struct DashScreen: View {
    private let model: DashModel

    init(model: DashModel) {
        self.model = model
    }

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            header
            Divider()
            if model.filtered.isEmpty {
                ContentUnavailableView(
                    "No open pull requests",
                    systemImage: "checkmark.circle",
                    description: Text(emptyDescription)
                )
                .frame(maxHeight: .infinity)
            } else {
                list
            }
        }
        .alert("GitHub request failed", isPresented: errorShown) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var header: some View {
        @Bindable var model = model

        return HStack(spacing: 12) {
            Text(model.repository.fullName)
                .font(.headline)
            Spacer()
            Picker("Filter", selection: $model.filter) {
                ForEach(DashFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            Button {
                Task { await model.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Reload")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var list: some View {
        List(model.filtered, id: \.number) { pullRequest in
            Button {
                Task { await model.openReview(of: pullRequest) }
            } label: {
                DashRowView(
                    pullRequest: pullRequest,
                    isOpening: model.openingNumber == pullRequest.number
                )
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(model.openingNumber != nil)
        }
        .listStyle(.inset)
    }

    private var emptyDescription: String {
        switch model.filter {
        case .all: "This repository has no open pull requests."
        case .mine: "No open pull requests authored by you."
        case .reviewRequested: "No open pull requests waiting for your review."
        }
    }

    private var errorShown: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }
}
