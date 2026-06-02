import Foundation
import SudoEmail

/// Resolves the appropriate swipe action titles for an email mask
/// based on its `realAddressType` and `status`.
///
/// For external masks, actions are determined by status:
/// - `.pending` → ["Verify", "Delete"]
/// - `.enabled` → ["Disable", "Delete"]
/// - `.disabled` → ["Enable", "Delete"]
/// - `.locked` → ["Delete"]
///
/// For internal masks, returns an empty array to indicate the caller
/// should delegate to existing swipe action logic.
struct SwipeActionResolver {

    /// Returns the swipe action titles appropriate for the given mask.
    ///
    /// - Parameter mask: The email mask to resolve actions for.
    /// - Returns: An array of action title strings for external masks,
    ///   or an empty array for internal masks (indicating existing logic should be used).
    static func actions(for mask: EmailMask) -> [String] {
        switch mask.realAddressType {
        case .external:
            switch mask.status {
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
