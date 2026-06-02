import SudoEmail

/// Filters a list of email masks by their real address type.
/// Used by EmailMaskListViewController to partition masks based on the selected segment.
struct MaskListFilter {
    /// Returns only masks whose `realAddressType` matches the given type.
    ///
    /// - Parameters:
    ///   - masks: The full list of email masks to filter.
    ///   - type: The `EmailMask.RealAddressType` to match against.
    /// - Returns: A subset of `masks` where each mask's `realAddressType` equals `type`.
    static func filter(masks: [EmailMask], byType type: EmailMask.RealAddressType) -> [EmailMask] {
        return masks.filter { $0.realAddressType == type }
    }
}
