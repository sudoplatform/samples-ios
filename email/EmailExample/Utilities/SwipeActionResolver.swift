import Foundation
import SudoEmail

/// Resolves the appropriate swipe action titles for an email alias
/// based on its `realAddressType` and `status`.
///
/// For external aliases, actions are determined by status:
/// - `.pending` → ["Verify", "Delete"]
/// - `.enabled` → ["Disable", "Delete"]
/// - `.disabled` → ["Enable", "Delete"]
/// - `.locked` → ["Delete"]
///
/// For internal aliases, returns an empty array to indicate the caller
/// should delegate to existing swipe action logic.
struct SwipeActionResolver {

    /// Returns the swipe action titles appropriate for the given alias.
    ///
    /// - Parameter alias: The email alias to resolve actions for.
    /// - Returns: An array of action title strings for external aliases,
    ///   or an empty array for internal aliases (indicating existing logic should be used).
    static func actions(for alias: EmailAlias) -> [String] {
        switch alias.realAddressType {
        case .external:
            switch alias.status {
            case .pending:
                return ["Verify", "Delete"]
            case .enabled:
                return ["Disable", "Delete"]
            case .disabled:
                return ["Enable", "Delete"]
            case .locked:
                return ["Delete"]
            }
        case .internal:
            return []
        }
    }
}
