import Foundation

/// Utility for validating verification code input.
/// Used by EmailMaskListViewController to enable/disable the confirm button
/// in the verification code entry dialog.
struct VerificationCodeValidation {

    /// Returns `true` if the code is non-empty and contains at least one non-whitespace character.
    /// Returns `false` for empty strings or strings containing only whitespace (spaces, tabs, newlines).
    static func isValid(_ code: String) -> Bool {
        !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
