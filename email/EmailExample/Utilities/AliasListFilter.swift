import SudoEmail

/// Filters a list of email aliases by their real address type.
/// Used by EmailAliasListViewController to partition aliases based on the selected segment.
struct AliasListFilter {
    /// Returns only aliases whose `realAddressType` matches the given type.
    ///
    /// - Parameters:
    ///   - aliases: The full list of email aliases to filter.
    ///   - type: The `EmailAlias.RealAddressType` to match against.
    /// - Returns: A subset of `aliases` where each alias's `realAddressType` equals `type`.
    static func filter(aliases: [EmailAlias], byType type: EmailAlias.RealAddressType) -> [EmailAlias] {
        return aliases.filter { $0.realAddressType == type }
    }
}
