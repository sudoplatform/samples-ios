// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen
// Custom template in `swiftgen/strings/template.stencil`

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name

internal enum L10n {

    // MARK: - relay
    internal enum Relay {
      // MARK: - errors
      internal enum Errors {
        internal static let accountLockedError = L10n.tr("Localizable", "relay.errors.accountLockedError")
        internal static let ambiguousRelayError = L10n.tr("Localizable", "relay.errors.ambiguousRelayError")
        internal static let decodingError = L10n.tr("Localizable", "relay.errors.decodingError")
        internal static let environmentError = L10n.tr("Localizable", "relay.errors.environmentError")
        internal static let identityInsufficient = L10n.tr("Localizable", "relay.errors.identityInsufficient")
        internal static let identityNotVerified = L10n.tr("Localizable", "relay.errors.identityNotVerified")
        internal static let insufficientRelayError = L10n.tr("Localizable", "relay.errors.insufficientRelayError")
        internal static let invalidArgument = L10n.tr("Localizable", "relay.errors.invalidArgument")
        internal static let invalidConfig = L10n.tr("Localizable", "relay.errors.invalidConfig")
        internal static let invalidInitMessage = L10n.tr("Localizable", "relay.errors.invalidInitMessage")
        internal static let invalidTokenError = L10n.tr("Localizable", "relay.errors.invalidTokenError")
        internal static let noEntitlementsError = L10n.tr("Localizable", "relay.errors.noEntitlementsError")
        internal static let noRelayError = L10n.tr("Localizable", "relay.errors.noRelayError")
        internal static let notSignedIn = L10n.tr("Localizable", "relay.errors.notSignedIn")
        internal static let policyFailed = L10n.tr("Localizable", "relay.errors.policyFailed")
        internal static let relayServiceConfigNotFound = L10n.tr("Localizable", "relay.errors.relayServiceConfigNotFound")
        internal static let serviceError = L10n.tr("Localizable", "relay.errors.serviceError")
        internal static let unknownTimezone = L10n.tr("Localizable", "relay.errors.unknownTimezone")
        internal static let unauthorizedPostboxAccess = L10n.tr("Localizable", "relay.errors.unauthorizedPostboxAccess")
      }
    }
}

// swiftlint:enable explicit_type_interface identifier_name line_length nesting type_body_length type_name

extension L10n {
  fileprivate static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: .sdkBundle, comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
