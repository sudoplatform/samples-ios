import Foundation

/// Utility for validating email address format.
/// Used by CreateEmailMaskViewController to validate external email input.
struct EmailValidation {

    /// Maximum allowed length for an email address (RFC 5321).
    static let maxLength: Int = 254

    /// Validates that the email contains exactly one `@`, at least one character before `@`,
    /// a domain after `@` that contains at least one `.` with characters on both sides,
    /// and that the total length does not exceed 254 characters.
    static func isValidFormat(_ email: String) -> Bool {
        // Check total length
        guard email.count <= maxLength else {
            return false
        }

        // Split on @ — must have exactly one
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            return false
        }

        let localPart = parts[0]
        let domainPart = parts[1]

        // At least one character before @
        guard !localPart.isEmpty else {
            return false
        }

        // Domain must contain at least one dot with characters on both sides
        let domainSegments = domainPart.split(separator: ".", omittingEmptySubsequences: false)
        guard domainSegments.count >= 2 else {
            return false
        }

        // Every segment must be non-empty (characters on both sides of each dot)
        for segment in domainSegments {
            if segment.isEmpty {
                return false
            }
        }

        return true
    }
}
