// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen
// Custom template in `swiftgen/strings/template.stencil`

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name

internal enum L10n {

    // MARK: - Relay

    internal enum Relay {

        // MARK: - Errors

        internal enum Errors {
            internal static let accountLocked = L10n.tr("Localizable", "relay.errors.accountLocked")
            internal static let decodingError = L10n.tr("Localizable", "relay.errors.decodingError")
            internal static let environmentError = L10n.tr("Localizable", "relay.errors.environmentError")
            internal static let insufficientRelayError = L10n.tr("Localizable", "relay.errors.insufficientRelayError")
            internal static let invalidArgument = L10n.tr("Localizable", "relay.errors.invalidArgument")
            internal static let invalidConfig = L10n.tr("Localizable", "relay.errors.invalidConfig")
            internal static let invalidMessageError = L10n.tr("Localizable", "relay.errors.invalidMessage")
            internal static let invalidPostboxError = L10n.tr("Localizable", "relay.errors.invalidPostbox")
            internal static let invalidTokenError = L10n.tr("Localizable", "relay.errors.invalidTokenError")
            internal static let noEntitlementsError = L10n.tr("Localizable", "relay.errors.noEntitlementsError")
            internal static let insufficientEntitlementsError = L10n.tr("Localizable", "relay.errors.insufficientEntitlementsError")
            internal static let noRelayError = L10n.tr("Localizable", "relay.errors.noRelayError")
            internal static let notSignedIn = L10n.tr("Localizable", "relay.errors.notSignedIn")
            internal static let policyFailed = L10n.tr("Localizable", "relay.errors.policyFailed")
            internal static let relayServiceConfigNotFound = L10n.tr("Localizable", "relay.errors.relayServiceConfigNotFound")
            internal static let serviceError = L10n.tr("Localizable", "relay.errors.serviceError")
            internal static let unknownTimezone = L10n.tr("Localizable", "relay.errors.unknownTimezone")
            internal static let unauthorizedPostboxAccess = L10n.tr("Localizable", "relay.errors.unauthorizedPostboxAccess")
            internal static let invalidPostboxInput = L10n.tr("Localizable", "relay.errors.invalidPostboxInput")
            internal static let notAuthorized = L10n.tr("Localizable", "relay.errors.notAuthorized")
            internal static let versionMismatch = L10n.tr("Localizable", "relay.errors.versionMismatch")
            internal static let requestFailed = L10n.tr("Localizable", "relay.errors.requestFailed")
            internal static let graphQLError = L10n.tr("Localizable", "relay.errors.graphQLError")
            internal static let fatalError = L10n.tr("Localizable", "relay.errors.fatalError")
            internal static let invalidRequest = L10n.tr("Localizable", "relay.errors.invalidRequest")
            internal static let limitExceeded = L10n.tr("Localizable", "relay.errors.limitExceeded")
            internal static let rateLimitExceeded = L10n.tr("Localizable", "relay.errors.rateLimitExceeded")
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
