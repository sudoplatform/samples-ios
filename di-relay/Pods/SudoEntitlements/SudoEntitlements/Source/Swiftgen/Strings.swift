// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen
// Custom template in `swiftgen/strings/template.stencil`

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name

internal enum L10n {

    // MARK: - entitlements
    internal enum Entitlements {
      // MARK: - errors
      internal enum Errors {
        internal static let accountLockedError = L10n.tr("Localizable", "entitlements.errors.accountLockedError")
        internal static let ambiguousEntitlementsError = L10n.tr("Localizable", "entitlements.errors.ambiguousEntitlementsError")
        internal static let decodingError = L10n.tr("Localizable", "entitlements.errors.decodingError")
        internal static let environmentError = L10n.tr("Localizable", "entitlements.errors.environmentError")
        internal static let identityInsufficient = L10n.tr("Localizable", "entitlements.errors.identityInsufficient")
        internal static let identityNotVerified = L10n.tr("Localizable", "entitlements.errors.identityNotVerified")
        internal static let insufficientEntitlementsError = L10n.tr("Localizable", "entitlements.errors.insufficientEntitlementsError")
        internal static let invalidConfig = L10n.tr("Localizable", "entitlements.errors.invalidConfig")
        internal static let invalidTokenError = L10n.tr("Localizable", "entitlements.errors.invalidTokenError")
        internal static let noEntitlementsError = L10n.tr("Localizable", "entitlements.errors.noEntitlementsError")
        internal static let notSignedIn = L10n.tr("Localizable", "entitlements.errors.notSignedIn")
        internal static let policyFailed = L10n.tr("Localizable", "entitlements.errors.policyFailed")
        internal static let serviceError = L10n.tr("Localizable", "entitlements.errors.serviceError")
        internal static let unknownTimezone = L10n.tr("Localizable", "entitlements.errors.unknownTimezone")
        internal static let invalidArgument = L10n.tr("Localizable", "entitlements.errors.invalidArgument")
        internal static let entitlementsServiceConfigNotFound = L10n.tr("Localizable", "entitlements.errors.entitlementsServiceConfigNotFound")
        internal static let limitExceeded = L10n.tr("Localizable", "entitlements.errors.limitExceeded")
        internal static let notAuthorized = L10n.tr("Localizable", "entitlements.errors.notAuthorized")
        internal static let requestFailed = L10n.tr("Localizable", "entitlements.errors.requestFailed")
        internal static let rateLimitExceeded = L10n.tr("Localizable", "entitlements.errors.rateLimitExceeded")
        internal static let graphQLError = L10n.tr("Localizable", "entitlements.errors.graphQLError")
        internal static let fatalError = L10n.tr("Localizable", "entitlements.errors.fatalError")
        internal static let invalidRequest = L10n.tr("Localizable", "entitlements.errors.invalidRequest")
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
