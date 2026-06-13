import Foundation
import SwiftUI

/// Liquid Glass author filter menu for the dashboard toolbar.
package struct DashboardAuthorFilterMenu: View {
    /// Shared dashboard filter state.
    package let filterState: DashboardFilterState

    private let spacing = LayoutSpacing()

    /// Creates an author filter menu.
    package init(filterState: DashboardFilterState) {
        self.filterState = filterState
    }

    /// Author filter menu content.
    package var body: some View {
        Menu {
            ForEach(DashboardAuthorFilter.allCases) { filter in
                Button {
                    filterState.authorFilter = filter
                } label: {
                    if filterState.authorFilter == filter {
                        Label(filter.title, systemImage: "checkmark")
                    } else {
                        Text(filter.title)
                    }
                }
            }
        } label: {
            HStack(spacing: spacing.small) {
                Text("Author")
                // Image(systemName: "chevron.down")
                //     .font(.caption)
            }
            .padding(.horizontal, spacing.large)
            .padding(.vertical, spacing.small)
        }
        .menuStyle(.button)
        .glassEffect(.regular, in: .capsule)
    }
}
