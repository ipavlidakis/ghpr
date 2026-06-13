import Foundation
import Observation

/// Main-actor dashboard filter state shared by the toolbar and table.
@MainActor
@Observable
package final class DashboardFilterState {
    /// Currently selected author filter.
    package var authorFilter: DashboardAuthorFilter

    /// Creates dashboard filter state.
    package init(authorFilter: DashboardAuthorFilter = .all) {
        self.authorFilter = authorFilter
    }
}
